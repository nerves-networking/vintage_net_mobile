defmodule VintageNetMobileTest.CustomModem do
  @behaviour VintageNetMobile.Modem

  alias VintageNet.Interface.RawConfig

  @impl true
  def add_raw_config(raw_config, config, _opts) do
    ifname = raw_config.ifname

    %RawConfig{
      raw_config
      | files: [{"chatscript.#{ifname}", "Service provider APNs are #{config.service_providers}"}]
    }
  end

  @impl true
  def validate_config(_), do: :ok

  @impl true
  def ready(), do: :ok
end
