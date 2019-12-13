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
    chatscript_path = Keyword.fetch!(state, :cs_path)
    pppd = Keyword.fetch!(state, :pppd)

    {_, 0} = System.cmd("mknod", ["/dev/ppp", "c", "108", "0"])

    MuonTrap.Daemon.start_link(
      pppd,
      [
        "connect",
        "/usr/sbin/chat -v -f #{chatscript_path}",
        "/dev/ttyUSB1",
        "115200",
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
