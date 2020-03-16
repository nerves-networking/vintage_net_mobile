defmodule VintageNetMobile.SignalMonitor do
  @moduledoc false

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
  require Logger
  alias VintageNet.PropertyTable
  alias VintageNetMobile.{ExChat, ATParser}

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

      # Spec says AT+CSQ max response time is 300 ms.
      _ = ExChat.send(state.tty, "AT+CSQ", timeout: 500)
      :ok
    else
      PropertyTable.put(VintageNet, ["interface", state.ifname, "mobile", "signal_rssi"], 99)
    end

    Process.send_after(self(), :signal_check, state.signal_check_interval)
    {:noreply, state}
  end

  def handle_info({:handle_csq, message}, state) do
    {:csq, {rssi, _bit_error_rate}} = ATParser.parse_at_response(message)

    PropertyTable.put(VintageNet, ["interface", state.ifname, "mobile", "signal_rssi"], rssi)

    {:noreply, state}
  end

  defp connected?(state) do
    VintageNet.get(["interface", state.ifname, "connection"]) == :internet
  end
end
