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
  | `iccid `      | string          | The Integrated Circuit Card Identifier |

  """
  use GenServer
  require Logger
  alias VintageNet.PropertyTable
  alias VintageNetMobile.{ExChat, ATParser}

  @iccid_unknown "Not provided"

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
    ExChat.register(tty, "+QCCID", fn message -> send(us, {:handle_qccid, message}) end)

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

  def handle_info({:handle_qccid, message}, state) do
    message
    |> ATParser.parse()
    |> iccid_response_to_qccid()
    |> post_iccid(state.ifname)

    {:noreply, state}
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "connection"], _old, :internet, _meta},
        %{ifname: ifname} = state
      ) do
    new_state = %{state | up: true}

    # Set the CREG report format just in case it hasn't been set.
    :ok = ExChat.send(new_state.tty, "AT+CREG=2", timeout: 1000)
    :ok = ExChat.send(new_state.tty, "AT+QCCID", timeout: 500)

    poll(new_state)

    {:noreply, new_state}
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "connection"], _old, _not_internet, _meta},
        %{ifname: ifname} = state
      ) do
    # Clear out properties!

    {:noreply, %{state | up: false}}
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
    %{stat: stat, lac: safe_hex_to_int(lac), ci: safe_hex_to_int(ci), act: act}
  end

  defp creg_response_to_registration(malformed) do
    _ = Logger.warn("Unexpected AT+CREG? response: #{inspect(malformed)}")
    %{stat: 0, lac: 0, ci: 0, act: 0}
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

  defp iccid_response_to_qccid({:ok, "+QCCID: ", [id]}) do
    id
  end

  defp iccid_response_to_qccid(anything_else) do
    _ = Logger.warn("Unexpected AT+QCCID response: #{inspect(anything_else)}")
    @iccid_unknown
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

  defp post_registration(%{lac: lac, ci: ci}, ifname) do
    PropertyTable.put(VintageNet, ["interface", ifname, "mobile", "lac"], lac)
    PropertyTable.put(VintageNet, ["interface", ifname, "mobile", "cid"], ci)
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

  defp post_iccid(iccid, ifname) do
    PropertyTable.put(VintageNet, ["interface", ifname, "mobile", "iccid"], iccid)
  end
end
