defmodule VintageNetMobileTest.CustomModem do
  @behaviour VintageNetMobile.Modem

  alias VintageNet.Interface.RawConfig

  @impl true
  def normalize(%{vintage_net_mobile: mobile} = config) do
    if Map.get(mobile, :complain, false) do
      raise ArgumentError, "CustomModem is not happy!"
    end

    config
  end

  @impl true
  def add_raw_config(raw_config, config, _opts) do
    ifname = raw_config.ifname

    %RawConfig{
      raw_config
      | files: [
          {"chatscript.#{ifname}",
           "The service providers are #{inspect(config.vintage_net_mobile.service_providers)}"}
        ]
    }
  end

  @impl true
  def ready(), do: :ok

  @impl true
  def validate_service_providers(_), do: :ok
end
