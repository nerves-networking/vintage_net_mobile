defmodule VintageNetMobile.SignalMonitor do
  @moduledoc """
  Monitor the cell signal levels

  This monitor queries the modem for cell signal level information and posts it to
  VintageNet properties.

  The following properties are reported:

  | Property       | Values       | Description                   |
  | -------------- | ------------ | ----------------------------- |
  | `signal_asu`   | `0-31,99`    | This is the raw Arbitrary Strength Unit (ASU) reported. It's interpretation depends on the modem and possibly the connection technology. |
  | `signal_4bars` | `0-4`        | The signal level in "bars" for presentation to a user. |
  | `signal_dbm`   | `-144 - -44` | The signal level in dBm. Interpretation depends on the connection technology. |
  """

  use GenServer
  require Logger

  alias VintageNet.PropertyTable
  alias VintageNetMobile.{ExChat, ATParser, ASUCalculator}

  @rssi_unknown ASUCalculator.from_gsm_asu(99)

  @typedoc """
  The options for the monitor are:

  * `:signal_check_interval` - the number of milliseconds to wait before asking
    the modem for the signal quality (default 5 seconds)
  * `:ifname` - the interface name the mobile connection is using
  * `:tty` - the tty name that is used to send AT commands
  """
  @type opt ::
          {:signal_check_interval, non_neg_integer()} | {:ifname, String.t()} | {:tty, String.t()}

  defmodule State do
    @moduledoc false

    defstruct signal_check_interval: nil, ifname: nil, tty: nil
  end

  @spec start_link([opt]) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :signal_check_interval, 5_000)
    ifname = Keyword.fetch!(opts, :ifname)
    tty = Keyword.fetch!(opts, :tty)

    Process.send_after(self(), :signal_check, interval)

    us = self()
    ExChat.register(tty, "+CSQ", fn message -> send(us, {:handle_csq, message}) end)
    {:ok, %State{signal_check_interval: interval, ifname: ifname, tty: tty}}
  end

  @impl true
  def handle_info(:signal_check, state) do
    if connected?(state) do
      # Only poll if connected, since some modems don't like it when they're not connected

      # Spec says AT+CSQ max response time is 500 ms.
      ExChat.send_best_effort(state.tty, "AT+CSQ", timeout: 500)
      :ok
    else
      post_signal_rssi(@rssi_unknown, state.ifname)
    end

    Process.send_after(self(), :signal_check, state.signal_check_interval)
    {:noreply, state}
  end

  def handle_info({:handle_csq, message}, state) do
    message
    |> ATParser.parse()
    |> csq_response_to_rssi()
    |> post_signal_rssi(state.ifname)

    {:noreply, state}
  end

  defp csq_response_to_rssi({:ok, _header, [asu, _error_rate]}) when is_integer(asu) do
    ASUCalculator.from_gsm_asu(asu)
  end

  defp csq_response_to_rssi(anything_else) do
    _ = Logger.warn("Unexpected AT+CSQ response: #{inspect(anything_else)}")
    @rssi_unknown
  end

  defp post_signal_rssi(%{asu: asu, dbm: dbm, bars: bars}, ifname) do
    PropertyTable.put(VintageNet, ["interface", ifname, "mobile", "signal_asu"], asu)
    PropertyTable.put(VintageNet, ["interface", ifname, "mobile", "signal_dbm"], dbm)
    PropertyTable.put(VintageNet, ["interface", ifname, "mobile", "signal_4bars"], bars)
  end

  defp connected?(state) do
    VintageNet.get(["interface", state.ifname, "connection"]) == :internet
  end
end
