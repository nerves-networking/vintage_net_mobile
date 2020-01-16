defmodule VintageNetLTE.ToElixir.PPPDHandler do
  @moduledoc """
  A behaviour for handling notifications from pppd

  # Example

  ```elixir
  defmodule MyApp.PPPDHandler do
    @behaviour VintageNetLTE.ToElixir.PPPDHandler

    @impl true
    def ip_up(ifname, data) do
      ...
    end
  end
  ```
  """

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
  This is called when after the remote system authenticates itself.

  If the `noauth` option is used by `pppd` then this will not be called
  """
  @callback auth_up(VintageNet.ifname(), update_data()) :: :ok

  @doc """
  Called internally by vintage_net_lte to dispatch calls
  """
  @spec dispatch(atom(), VintageNet.ifname(), update_data()) :: :ok
  def dispatch(function, ifname, update_data) do
    handler = Application.get_env(:vintage_net_lte, :pppd_handler)
    apply(handler, function, [ifname, update_data])
  end
end
