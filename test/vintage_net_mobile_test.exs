defmodule VintageNetMobileTest do
  use ExUnit.Case

  alias VintageNet.Interface.RawConfig
  alias VintageNetMobileTest.{CustomModem, Utils}

  test "create a configuration for a custom mode" do
    input = %{
      type: VintageNetMobile,
      modem: VintageNetMobileTest.CustomModem,
      service_providers: [%{apn: "free_lte"}]
    }

    output = %RawConfig{
      ifname: "ppp0",
      type: VintageNetMobile,
      source_config: input,
      files: [{"chatscript.ppp0", "The service providers are [%{apn: \"free_lte\"}]"}],
      up_cmds: [
        {:fun, CustomModem, :ready, []},
        {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]}
      ],
      down_cmds: [
        {:fun, VintageNet.PropertyTable, :clear_prefix,
         [VintageNet, ["interface", "ppp0", "mobile"]]}
      ]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end

  test "raises when service providers list is invalid" do
    input = %{
      type: VintageNetMobile,
      modem: VintageNetMobile.Modem.QuectelBG96,
      service_providers: []
    }

    assert_raise ArgumentError, fn ->
      VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
    end
  end

  test "raises when unknown modem" do
    input = %{
      type: VintageNetMobile,
      modem: VintageNetMobile.Modem.DoesNotExist,
      service_providers: [%{apn: "apn"}]
    }

    assert_raise UndefinedFunctionError, fn ->
      VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
    end
  end
end
