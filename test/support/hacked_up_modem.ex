defmodule VintageNetMobileTest.HackedUpModem do
  @behaviour VintageNetMobile.Modem

  alias VintageNet.Interface.RawConfig

  @impl true
  def specs() do
    # Support only one LTE provider since this example is for setups
    # that are too hard to make generic.
    [{"Hacked Up Modem", [%{apn: "bobslte"}]}]
  end

  @impl true
  def add_raw_config(raw_config, _config, _opts) do
    ifname = raw_config.ifname

    %RawConfig{
      raw_config
      | files: [{"chatscript.#{ifname}", "Bob is awesome"}]
    }
  end

  @impl true
  def ready(), do: :ok

  @impl true
  def validate_service_providers(_), do: :ok
end
