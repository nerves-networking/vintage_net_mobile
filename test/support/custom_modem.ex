defmodule VintageNetMobileTest.CustomModem do
  @behaviour VintageNetMobile.Modem

  alias VintageNet.Interface.RawConfig

  @impl true
  def specs() do
    # Support all service providers
    [{"Custom Modem", :_}]
  end

  @impl true
  def add_raw_config(raw_config, config, _opts) do
    ifname = raw_config.ifname

    %RawConfig{
      raw_config
      | files: [{"chatscript.#{ifname}", "The service providers are #{config.service_providers}"}]
    }
  end

  @impl true
  def ready(), do: :ok

  @impl true
  def validate_service_providers(_), do: :ok
end
