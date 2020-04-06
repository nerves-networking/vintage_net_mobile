defmodule VintageNetMobile.ModemInfo do
  @moduledoc """
  Query the modem for device and SIM information

  This monitor queries the modem for information about itself and its SIM and
  posts it to VintageNet properties.

  The following properties are reported:

  | Property      | Values         | Description                   |
  | ------------- | -------------- | ----------------------------- |
  | `iccid `      | string         | The Integrated Circuit Card Identifier |

  """
  use GenServer
  require Logger
  alias VintageNet.PropertyTable
  alias VintageNetMobile.{ExChat, ATParser}

  @unknown "Unknown"

  defmodule State do
    @moduledoc false

    defstruct ifname: nil, tty: nil
  end

  @spec start_link([keyword()]) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    ifname = Keyword.fetch!(opts, :ifname)
    tty = Keyword.fetch!(opts, :tty)

    us = self()
    ExChat.register(tty, "+QCCID", fn message -> send(us, {:handle_qccid, message}) end)

    Process.send_after(us, :poll, 500)

    {:ok, %State{ifname: ifname, tty: tty}}
  end

  @impl true
  def handle_info(:poll, state) do
    {:ok, _} = ExChat.send(state.tty, "ATE0", timeout: 500)
    {:ok, _} = ExChat.send(state.tty, "AT+QCCID", timeout: 500)

    {:noreply, state}
  end

  def handle_info({:handle_qccid, message}, state) do
    message
    |> ATParser.parse()
    |> iccid_response_to_qccid()
    |> post_iccid(state.ifname)

    # Nothing more to do
    {:noreply, state, :hibernate}
  end

  defp iccid_response_to_qccid({:ok, "+QCCID: ", [id]}) do
    id
  end

  defp iccid_response_to_qccid(anything_else) do
    _ = Logger.warn("Unexpected AT+QCCID response: #{inspect(anything_else)}")
    @unknown
  end

  defp post_iccid(iccid, ifname) do
    PropertyTable.put(VintageNet, ["interface", ifname, "mobile", "iccid"], iccid)
  end
end
