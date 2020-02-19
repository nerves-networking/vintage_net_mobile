defmodule VintageNetLTE.SignalMonitor do
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
  alias VintageNetLTE.{ATRunner, ATParser}

  defmodule State do
    @moduledoc false

    defstruct signal_check_interval: nil, ifname: nil, tty: nil, connection: nil
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

    :timer.send_interval(interval, self(), :signal_check)
    VintageNet.subscribe(["interface", ifname, "connection"])

    {:ok,
     %State{
       signal_check_interval: interval,
       ifname: ifname,
       tty: tty,
       connection: :disconnected
     }}
  end

  @impl true
  def handle_info(
        {VintageNet, ["interface", ifname, "connection"], _old, status, _metadata},
        %{ifname: ifname} = state
      ) do
    {:noreply, %{state | connection: status}}
  end

  @impl true
  def handle_info(:signal_check, %{connection: :disconnected} = state) do
    {:noreply, state}
  end

  def handle_info(:signal_check, state) do
    {:ok, messages} = ATRunner.send(state.tty, "AT+CSQ", "OK")

    case Enum.find(messages, &String.starts_with?(&1, "+CSQ")) do
      nil ->
        {:noreply, state}

      at_response ->
        {:csq, {rssi, _bit_error_rate}} = ATParser.parse_at_response(at_response)
        PropertyTable.put(VintageNet, ["interface", state.ifname, "lte", "signal_rssi"], rssi)
        {:noreply, state}
    end
  end
end
