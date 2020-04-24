defmodule VintageNetMobile.CellMonitor do
  @moduledoc """
  Monitor cell network information

  This monitor queries the modem for cell network information and posts it to
  VintageNet properties.

  The following properties are reported:

  | Property      | Values         | Description                   |
  | ------------- | -------------- | ----------------------------- |
  | `lac`         | `0-65533`      | The Location Area Code (lac) for the current cell |
  | `cid`         | `0-268435455`  | The Cell ID (cid) for the current cell |
  | `mcc`         | `0-999`        | Mobile Country Code for the network |
  | `mnc`         | `0-999`        | Mobile Network Code for the network |
  | `network`     | string         | The network operator's name |
  | `access_technology` | string   | The technology currently in use to connect to the network |
  | `band`        | string         | The frequency band in use |
  | `channel`     | integer        | An integer that indicates the channel that's in use |

  """
  use GenServer
  require Logger
  alias VintageNet.PropertyTable
  alias VintageNetMobile.{ExChat, ATParser}

  defmodule State do
    @moduledoc false

    defstruct up: false, ifname: nil, tty: nil
  end

  @spec start_link([keyword()]) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    ifname = Keyword.fetch!(opts, :ifname)
    tty = Keyword.fetch!(opts, :tty)

    VintageNet.subscribe(["interface", ifname, "connection"])
    us = self()
    ExChat.register(tty, "+CREG:", fn message -> send(us, {:handle_creg, message}) end)
    ExChat.register(tty, "+QSPN:", fn message -> send(us, {:handle_qspn, message}) end)
    ExChat.register(tty, "+QNWINFO:", fn message -> send(us, {:handle_qnwinfo, message}) end)

    _ = :timer.send_interval(30_000, :poll)

    {:ok, %State{ifname: ifname, tty: tty}}
  end

  @impl true
  def handle_info({:handle_creg, message}, state) do
    message
    |> ATParser.parse()
    |> creg_response_to_registration()
    |> post_registration(state.ifname)

    {:noreply, state}
  end

  def handle_info({:handle_qspn, message}, state) do
    message
    |> ATParser.parse()
    |> qspn_response_to_network()
    |> post_network(state.ifname)

    {:noreply, state}
  end

  def handle_info({:handle_qnwinfo, message}, state) do
    message
    |> ATParser.parse()
    |> qnwinfo_response_to_info()
    |> post_qnwinfo(state.ifname)

    {:noreply, state}
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "connection"], _old, :internet, _meta},
        %{ifname: ifname} = state
      ) do
    new_state = %{state | up: true}

    # Set the CREG report format just in case it hasn't been set.
    {:ok, _} = ExChat.send(new_state.tty, "AT+CREG=2", timeout: 1000)

    poll(new_state)

    {:noreply, new_state}
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "connection"], _old, _not_internet, _meta},
        %{ifname: ifname} = state
      ) do
    # NOTE: None of this should depend on whether there's an Internet connection. At
    # one point, some trouble was seen when polling status and not connected. The easy
    # solution was to not poll. This should be revisited since might be valuable to
    # know that you're connected to a cell tower, but ppp isn't working.

    new_state = %{state | up: false}

    # Reset cell connection properties
    post_registration(%{stat: :unknown}, ifname)

    {:noreply, new_state}
  end

  def handle_info(:poll, state) do
    poll(state)
    {:noreply, state}
  end

  defp poll(%{up: true} = state) do
    ExChat.send_best_effort(state.tty, "AT+CREG?", timeout: 1000)
    ExChat.send_best_effort(state.tty, "AT+QNWINFO", timeout: 1000)
    ExChat.send_best_effort(state.tty, "AT+QSPN", timeout: 1000)
  end

  defp poll(_state), do: :ok

  defp creg_response_to_registration({:ok, _header, [2, stat, lac, ci, act]})
       when is_integer(stat) and is_binary(lac) and is_binary(ci) and is_integer(act) do
    %{stat: decode_stat(stat), lac: safe_hex_to_int(lac), ci: safe_hex_to_int(ci), act: act}
  end

  defp creg_response_to_registration({:ok, _header, [2, stat]}) when is_integer(stat) do
    %{stat: decode_stat(stat), lac: 0, ci: 0, act: 0}
  end

  defp creg_response_to_registration(malformed) do
    _ = Logger.warn("Unexpected AT+CREG? response: #{inspect(malformed)}")
    %{stat: :invalid, lac: 0, ci: 0, act: 0}
  end

  defp qspn_response_to_network({:ok, _header, [fnn, snn, spn, alphabet, plmn]})
       when is_binary(fnn) and is_binary(snn) and is_binary(spn) and is_integer(alphabet) and
              is_binary(plmn) do
    {mcc, mnc} = plmn_to_mcc_mnc(plmn)
    %{network_name: fnn, mcc: mcc, mnc: mnc}
  end

  defp qspn_response_to_network(malformed) do
    _ = Logger.warn("Unexpected AT+QSPN response: #{inspect(malformed)}")
    %{network_name: "", mcc: 0, mnc: 0}
  end

  defp qnwinfo_response_to_info({:ok, _header, [act, oper, band, channel]})
       when is_binary(act) and is_binary(oper) and is_binary(band) and is_integer(channel) do
    %{act: act, band: band, channel: channel}
  end

  defp qnwinfo_response_to_info(malformed) do
    _ = Logger.warn("Unexpected AT+QNWINFO response: #{inspect(malformed)}")
    %{act: "UNKNOWN", band: "", channel: 0}
  end

  defp plmn_to_mcc_mnc(<<mcc::3-bytes, mnc::3-bytes>>) do
    {safe_decimal_to_int(mcc), safe_decimal_to_int(mnc)}
  end

  defp plmn_to_mcc_mnc(<<mcc::3-bytes, mnc::2-bytes>>) do
    {safe_decimal_to_int(mcc), safe_decimal_to_int(mnc)}
  end

  defp plmn_to_mcc_mnc(other) do
    {safe_decimal_to_int(other), 0}
  end

  defp safe_hex_to_int(hex_string) do
    case Integer.parse(hex_string, 16) do
      {value, ""} -> value
      _other -> 0
    end
  end

  defp safe_decimal_to_int(string) do
    case Integer.parse(string) do
      {value, ""} -> value
      _other -> 0
    end
  end

  defp decode_stat(0), do: :not_registered_not_looking
  defp decode_stat(1), do: :registered_home_network
  defp decode_stat(2), do: :not_registered_looking
  defp decode_stat(3), do: :registration_denied
  defp decode_stat(4), do: :unknown
  defp decode_stat(5), do: :registered_roaming
  defp decode_stat(_), do: :invalid

  defp post_registration(%{stat: stat, lac: lac, ci: ci}, ifname)
       when stat in [:registered_home_network, :registered_roaming] do
    PropertyTable.put(VintageNet, ["interface", ifname, "mobile", "lac"], lac)
    PropertyTable.put(VintageNet, ["interface", ifname, "mobile", "cid"], ci)
  end

  defp post_registration(%{stat: _stat}, ifname) do
    # Disconnected case, so clear out properties reported by the cell monitor
    PropertyTable.clear(VintageNet, ["interface", ifname, "mobile", "lac"])
    PropertyTable.clear(VintageNet, ["interface", ifname, "mobile", "cid"])
    PropertyTable.clear(VintageNet, ["interface", ifname, "mobile", "network"])
    PropertyTable.clear(VintageNet, ["interface", ifname, "mobile", "mcc"])
    PropertyTable.clear(VintageNet, ["interface", ifname, "mobile", "mnc"])
    PropertyTable.clear(VintageNet, ["interface", ifname, "mobile", "access_technology"])
    PropertyTable.clear(VintageNet, ["interface", ifname, "mobile", "band"])
    PropertyTable.clear(VintageNet, ["interface", ifname, "mobile", "channel"])
  end

  defp post_network(%{network_name: name, mcc: mcc, mnc: mnc}, ifname) do
    PropertyTable.put(VintageNet, ["interface", ifname, "mobile", "network"], name)
    PropertyTable.put(VintageNet, ["interface", ifname, "mobile", "mcc"], mcc)
    PropertyTable.put(VintageNet, ["interface", ifname, "mobile", "mnc"], mnc)
  end

  defp post_qnwinfo(%{act: act, band: band, channel: channel}, ifname) do
    PropertyTable.put(VintageNet, ["interface", ifname, "mobile", "access_technology"], act)
    PropertyTable.put(VintageNet, ["interface", ifname, "mobile", "band"], band)
    PropertyTable.put(VintageNet, ["interface", ifname, "mobile", "channel"], channel)
  end
end
