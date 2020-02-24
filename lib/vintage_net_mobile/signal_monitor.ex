defmodule VintageNetMobile.SignalMonitor do
  @moduledoc """
  Monitor the signal quality of the modem
  """

  @typedoc """
  The options for the monitor are:

  * `:signal_check_interval` - the number of milliseconds to wait before asking
    the modem for the signal quality (default 5 seconds)
  * `:ifname` - the interface name the mobile connection is using
  * `:tty` - the tty name that is used to send AT commands
  """
  @type opt ::
          {:signal_check_interval, non_neg_integer()} | {:ifname, String.t()} | {:tty, String.t()}

  use GenServer

  alias VintageNet.PropertyTable
  alias VintageNetMobile.{ATRunner, ATParser}

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

    _ = signal_check_timer(interval)

    {:ok, %State{signal_check_interval: interval, ifname: ifname, tty: tty}}
  end

  @impl true
  def handle_info(:signal_check, state) do
    {:ok, messages} = ATRunner.send(state.tty, "AT+CSQ", "OK")

    case Enum.find(messages, &String.starts_with?(&1, "+CSQ")) do
      nil ->
        {:noreply, state}

      at_response ->
        {:csq, {rssi, _bit_error_rate}} = ATParser.parse_at_response(at_response)

        PropertyTable.put(VintageNet, ["interface", state.ifname, "mobile", "signal_rssi"], rssi)

        _ = signal_check_timer(state.signal_check_interval)

        {:noreply, state}
    end
  end

  defp signal_check_timer(interval) do
    Process.send_after(self(), :signal_check, interval)
  end
end
