defmodule VintageNetLTE.PPPDNotifications do
  @behaviour VintageNetLTE.ToElixir.PPPDHandler

  alias VintageNet.{NameResolver, RouteManager}

  require Logger

  defp parse_address(address) do
    {:ok, ip} = :inet.parse_address(to_charlist(address))
    ip
  end

  # Matt - one of the callbacks should clear the address when the connection goes away

  @doc """
  Handle renew reports from udhcpc
  """
  @impl true
  def ip_up(ifname, info) do
    _ = Logger.debug("pppd.ip_up(#{ifname}): #{inspect(info)}")

    #  2:52:27.514 [error] ppp_to_elixir: dropping unknown report '{["ip-up", "ppp0", "/dev/ttyUSB0", "115200", "162.175.202.224", "10.64.64.64"],
    #  %{DEVICE: "/dev/ttyUSB0", DNS1: "10.177.0.34", DNS2: "10.177.0.210", IFNAME: "ppp0", IPLOCAL: "162.175.202.224", IPREMOTE: "10.64.64.64",
    #  ORIG_UID: "0", PPPD_PID: "278", PPPLOGNAME: "root", SPEED: "115200", USEPEERDNS: "1"}}''

    local_ip_address = parse_address(Map.get(info, :IPLOCAL))
    remote_ip_address = parse_address(Map.get(info, :IPREMOTE))

    RouteManager.set_route(ifname, [{local_ip_address, 30}], remote_ip_address, :internet)

    # Matt - I don't know how many DNS servers can be returned or even if none is valid.
    #        It seems like this should handle a variable amount
    dns1 = parse_address(Map.get(info, :DNS1))
    dns2 = parse_address(Map.get(info, :DNS2))
    domain = nil

    NameResolver.setup(ifname, domain, [dns1, dns2])
    :ok
  end

  @doc """
  Handle when the pppd link goes down
  """
  @impl true
  def ip_down(ifname, info) do
    _ = Logger.debug("pppd.ip_down(#{ifname}): #{inspect(info)}")

    RouteManager.clear_route(ifname)
    NameResolver.clear(ifname)

    :ok
  end

  @doc """
  Handle when the ppp connection is established with IPv6 enabled
  """
  @impl true
  def ipv6_up(ifname, info) do
    Logger.debug("pppd.ipv6_up(#{ifname}): #{inspect(info)}")
  end

  @doc """
  Handle when the ppp connection is lost with IPv6 enabled
  """
  @impl true
  def ipv6_down(ifname, info) do
    Logger.debug("pppd.ipv6_down(#{ifname}): #{inspect(info)}")
  end

  @doc """
  Handle when the interface is down but exists and has IP addresses
  """
  @impl true
  def ip_pre_up(ifname, info) do
    Logger.debug("pppd.ip_pre_up(#{ifname}): #{inspect(info)}")
  end

  @doc """
  Handle when the remote authenticates itself
  """
  @impl true
  def auth_up(ifname, info) do
    Logger.debug("pppd.auth_up(#{ifname}): #{inspect(info)}")
  end

  @doc """
  Handle auth when a connection goes down
  """
  @impl true
  def auth_down(ifname, info) do
    Logger.debug("pppd.auth_down(#{ifname}): #{inspect(info)}")
  end
end
