defmodule VintageNetLTE.PPPD do
  use GenServer

  def start_link(opts) do
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

    {_, 0} = System.cmd("mknod", ["/dev/ppp", "c", "108", "0"])

    MuonTrap.Daemon.start_link(
      pppd_bin,
      [
        "connect",
        "#{chat_bin} -v -f #{chatscript_path}",
        serial_port,
        speed,
        "noipdefault",
        "usepeerdns",
        "defaultroute",
        "persist",
        "noauth"
      ]
    )

    {:noreply, state}
  end
end
