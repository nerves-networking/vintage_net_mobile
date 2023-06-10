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

  alias VintageNet.PowerManager
  alias VintageNetMobile.ASUCalculator
  alias VintageNetMobile.ATParser
  alias VintageNetMobile.ExChat

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

  @impl GenServer
  def init(opts) do
    interval = Keyword.get(opts, :signal_check_interval, 5_000)
    ifname = Keyword.fetch!(opts, :ifname)
    tty = Keyword.fetch!(opts, :tty)

    Process.send_after(self(), :signal_check, interval)

    us = self()
    ExChat.register(tty, "+CSQ", fn message -> send(us, {:handle_csq, message}) end)
    {:ok, %State{signal_check_interval: interval, ifname: ifname, tty: tty}}
  end

  @impl GenServer
  def handle_info(:signal_check, state) do
    if connected?(state) do
      # Only poll if connected, since some modems don't like it when they're not connected

      # The AT+CSQ response should be quick. Quectel specifies a max response of 300 ms for
      # the BG96 and EC25. Other modules should be similar.
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
    |> maybe_pet_power_control(state.ifname)
    |> post_signal_rssi(state.ifname)

    {:noreply, state}
  end

  defp csq_response_to_rssi({:ok, _header, [asu, _error_rate]}) when is_integer(asu) do
    ASUCalculator.from_gsm_asu(asu)
  end

  defp csq_response_to_rssi(anything_else) do
    Logger.warn("Unexpected AT+CSQ response: #{inspect(anything_else)}")
    @rssi_unknown
  end

  defp post_signal_rssi(%{asu: asu, dbm: dbm, bars: bars}, ifname) do
    PropertyTable.put_many(VintageNet, [
      {["interface", ifname, "mobile", "signal_asu"], asu},
      {["interface", ifname, "mobile", "signal_dbm"], dbm},
      {["interface", ifname, "mobile", "signal_4bars"], bars}
    ])
  end

  defp connected?(state) do
    VintageNet.get(["interface", state.ifname, "connection"]) == :internet
  end

  # Report that the LTE modem is doing ok if it's connected to a tower
  # with 1 or more bars. 0 means that there's no connection.
  defp maybe_pet_power_control(%{bars: bars} = report, ifname) when bars > 0 do
    PowerManager.PMControl.pet_watchdog(ifname)
    report
  end

  defp maybe_pet_power_control(report, _ifname), do: report
end
