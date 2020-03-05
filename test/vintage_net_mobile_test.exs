defmodule VintageNetMobileTest do
  use ExUnit.Case

  alias VintageNet.Interface.RawConfig
  alias VintageNetMobileTest.{CustomModem, HackedUpModem, Utils}

  test "create a configuration for a custom mode" do
    input = %{type: VintageNetMobile, modem: CustomModem, service_providers: ["freelte"]}

    output = %RawConfig{
      ifname: "ppp0",
      type: VintageNetMobile,
      source_config: input,
      files: [{"chatscript.ppp0", "Service provider APNs are freelte"}],
      up_cmds: [{:fun, CustomModem, :ready, []}]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end

  test "create a configuration for a hacked up config" do
    input = %{type: VintageNetMobile, modem: HackedUpModem, service_providers: ["epiclte"]}

    assert_raise ArgumentError, fn ->
      VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
    end
  end
end
