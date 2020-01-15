defmodule VintageNetLTE.PPPD do
  use GenServer
  require Logger

  def start_link(opts) do
    _ = Logger.error("Starting PPPD!!!!!!!!!!!!!!!!!!!!")
    ifname = Keyword.fetch!(opts, :ifname)
    GenServer.start_link(__MODULE__, opts, name: via_name(ifname))
  end

  defp via_name(ifname) do
    {:via, Registry, {VintageNet.Interface.Registry, {__MODULE__, ifname}}}
  end

  def init(opts) do
    {:ok, opts, {:continue, :start_pppd}}
  end

  def handle_continue(:start_pppd, state) do
    chatscript_path = Keyword.fetch!(state, :chatscript)
    pppd_bin = Keyword.fetch!(state, :pppd)
    chat_bin = Keyword.fetch!(state, :chat)
    speed = Keyword.fetch!(state, :speed)
    serial_port = Keyword.fetch!(state, :serial)

    # The purpose of the pppd_shim is to redirect hardcoded calls to helper scripts
    # in pppd to programs in our priv directory.
    priv_dir = Application.app_dir(:vintage_net_lte, "priv")
    pppd_shim_path = Path.join(priv_dir, "pppd_shim.so")

    _ =
      Logger.error(
        "#{pppd_bin} connect #{chat_bin} -v -f #{chatscript_path} #{serial_port} #{speed}"
      )

    # TODO: make pppd options config item
    MuonTrap.Daemon.start_link(
      pppd_bin,
      [
        "connect",
        "#{chat_bin} -v -f #{chatscript_path}",
        serial_port,
        speed,
        "noipdefault",
        "usepeerdns",
        #        "defaultroute",
        "persist",
        "noauth",
        "debug"
      ],
      env: [{"PRIV_DIR", priv_dir}, {"LD_PRELOAD", pppd_shim_path}]
    )

    {:noreply, state}
  end
end
