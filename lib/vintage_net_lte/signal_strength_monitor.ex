defmodule VintageNetLTE.SignalStrengthMonitor do
  @moduledoc """
  Monitor the signal strength of the LTE modem

  This currently works by opening a UART connection to a the modem and queries
  the signal strength at a set interval.
  """

  @typedoc """
  Options for the monitor

  * `:speed` - the baud rate of the serial connection (default 115_200)
  * `:interval` - the interval to query the signal strength (default 5 seconds)
  * `:ifname` - the interface name for the `ppp` connection (required)
  * `:tty` - the tty device to connect to (required)
  """
  @type opt ::
          {:speed, non_neg_integer()}
          | {:interval, non_neg_integer()}
          | {:ifname, String.t()}
          | {:tty, String.t()}

  use GenServer

  alias Circuits.UART
  alias VintageNetLTE.{SignalStrength, ATBuffer}

  @spec start_link([opt]) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    speed = Keyword.get(opts, :speed, 115_200)
    interval = Keyword.get(opts, :interval, 5_000)
    tty = Keyword.fetch!(opts, :tty)
    ifname = Keyword.fetch!(opts, :ifname)

    {:ok, uart} = UART.start_link()

    :ok =
      UART.open(uart, tty,
        speed: speed,
        framing: {UART.Framing.Line, separator: "\r\n"}
      )

    timer = signal_check_timer(interval)

    {:ok,
     %{
       uart: uart,
       timer: timer,
       ifname: ifname,
       tty: tty,
       interval: interval,
       response_buffer: []
     }}
  end

  @impl true
  def handle_info(
        {:circuits_uart, tty, at_response},
        %{tty: tty, response_buffer: buffer, ifname: ifname} = state
      ) do
    case ATBuffer.handle_report(buffer, at_response) do
      {:continue, at_buffer} ->
        {:noreply, %{state | response_buffer: at_buffer}}

      {:complete, reports} ->
        [{:csq_report, {rssi, _error_rate}}] = ATBuffer.filter_reports(reports, :csq_report)

        SignalStrength.set_signal_properties(rssi, ifname)

        {:noreply, %{state | response_buffer: []}}
    end
  end

  @impl true
  def handle_info(:signal_check, state) do
    %{uart: uart, interval: interval} = state

    :ok = UART.write(uart, "AT+CSQ")

    {:noreply, %{state | timer: signal_check_timer(interval)}}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  defp signal_check_timer(interval) do
    Process.send_after(self(), :signal_check, interval)
  end
end
