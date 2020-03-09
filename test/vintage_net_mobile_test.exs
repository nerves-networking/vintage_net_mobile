defmodule VintageNetMobileTest do
  use ExUnit.Case

  alias VintageNet.Interface.RawConfig
  alias VintageNetMobileTest.{CustomModem, Utils}

  test "create a configuration for a custom mode" do
    input = %{type: VintageNetMobile, modem: "Custom Modem", service_providers: ["freelte"]}

    output = %RawConfig{
      ifname: "ppp0",
      type: VintageNetMobile,
      source_config: input,
      files: [{"chatscript.ppp0", "The service providers are freelte"}],
      up_cmds: [{:fun, CustomModem, :ready, []}]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end

  test "create a configuration for a hacked up config" do
    input = %{type: VintageNetMobile, modem: "Hacked Up Modem ", service_providers: ["epiclte"]}

    assert_raise ArgumentError, fn ->
      VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
    end
  end

  test "raise error when modems are not valid" do
    input = %{type: VintageNetMobile, modem: "Quectel BG96", service_providers: []}

    assert_raise ArgumentError, fn ->
      VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
    end
  end
end
