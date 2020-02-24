defmodule VintageNetMobileTest do
  use ExUnit.Case

  alias VintageNet.Interface.RawConfig

  test "create a configuration for a provider-less custom modem" do
    input = %{type: VintageNetMobile, modem: "Custom Modem", service_provider: "Twilio"}

    output = %RawConfig{
      ifname: "ppp0",
      type: VintageNetMobile,
      source_config: input,
      files: [{"chatscript.ppp0", "Service provider is Twilio"}]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end

  test "create a configuration for a provider-ful custom modem" do
    input = %{type: VintageNetMobile, modem: "Hacked Up Modem", service_provider: "Bob's LTE"}

    output = %RawConfig{
      ifname: "ppp0",
      type: VintageNetMobile,
      source_config: input,
      files: [{"chatscript.ppp0", "Bob is awesome"}]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end

  test "create a configuration for a user-provided service provider" do
    input = %{type: VintageNetMobile, modem: "Custom Modem", service_provider: "Wilbur's LTE"}

    output = %RawConfig{
      ifname: "ppp0",
      type: VintageNetMobile,
      source_config: input,
      files: [{"chatscript.ppp0", "Service provider is Wilbur's LTE"}]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end
end
