defmodule VintageNetMobile.ToElixir.PPPDHandler do
  @moduledoc false

  # A behaviour for handling notifications from pppd
  #
  # # Example
  #
  # ```elixir
  # defmodule MyApp.PPPDHandler do
  #   @behaviour VintageNetMobile.ToElixir.PPPDHandler
  #
  #   @impl true
  #   def ip_up(ifname, data) do
  #     ...
  #   end
  # end
  # ```

  @type update_data :: map()

  @doc """
  This is called when pppd successfully establishes a connection.
  """
  @callback ip_up(VintageNet.ifname(), update_data()) :: :ok

  @doc """
  This is called when the ppp connection is lost
  """
  @callback ip_down(VintageNet.ifname(), update_data()) :: :ok

  @doc """
  This is called just before the ppp network interface is brought up. At this
  point the interface exists and has IP address but is still down.

  This is useful for adding firewall rules before any IP traffic can pass
  through
  """
  @callback ip_pre_up(VintageNet.ifname(), update_data()) :: :ok

  @doc """
  This is called when pppd successfully establishes a connection and IPv6
  addressing is enabled
  """
  @callback ipv6_up(VintageNet.ifname(), update_data()) :: :ok

  @doc """
  This is called when pppd loses the connection and IPv6 addressing is enabled
  """
  @callback ipv6_down(VintageNet.ifname(), update_data()) :: :ok

  @doc """
  This is called after the remote system authenticates itself.

  If the `noauth` option is used by `pppd` then this will not be called
  """
  @callback auth_up(VintageNet.ifname(), update_data()) :: :ok

  @doc """
  This is called when the connection is lost if authentication was used when
  the connection was established.
  """
  @callback auth_down(VintageNet.ifname(), update_data()) :: :ok

  @doc """
  Called internally by vintage_net_mobile to dispatch calls
  """
  @spec dispatch(atom(), VintageNet.ifname(), update_data()) :: :ok
  def dispatch(function, ifname, update_data) do
    handler = Application.get_env(:vintage_net_mobile, :pppd_handler)
    apply(handler, function, [ifname, update_data])
  end
end
