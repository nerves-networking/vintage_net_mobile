defmodule VintageNetMobile.Modem.Automatic do
  @moduledoc """
  Modem for automatic detection and configuration of USB-based modems

  This is useful for when you need to support different types of modems and you
  cannot provide a static configuration for one particular modem.
  """
  @behaviour VintageNetMobile.Modem

  alias VintageNet.Interface.RawConfig
  alias VintageNetMobile.Modem.Automatic.Discovery

  @impl VintageNetMobile.Modem
  def normalize(config), do: config

  @impl VintageNetMobile.Modem
  def add_raw_config(raw_config, %{vintage_net_mobile: _mobile}, _opts) do
    child_specs = [
      {Discovery, [raw_config: raw_config]}
    ]

    %RawConfig{
      raw_config
      | child_specs: child_specs
    }
  end
end
