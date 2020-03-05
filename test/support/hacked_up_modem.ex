defmodule VintageNetMobileTest.HackedUpModem do
  @behaviour VintageNetMobile.Modem

  alias VintageNet.Interface.RawConfig

  @impl true
  def add_raw_config(raw_config, _config, _opts) do
    ifname = raw_config.ifname

    %RawConfig{
      raw_config
      | files: [{"chatscript.#{ifname}", "Bob is awesome"}]
    }
  end

  @impl true
  def validate_config(_config), do: {:error, :invalid}

  @impl true
  def ready(), do: :ok
end
