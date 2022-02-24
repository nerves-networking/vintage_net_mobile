defmodule VintageNetMobile.Modem.AutomaticTest do
  use ExUnit.Case, async: true

  alias VintageNetMobile.Modem.Automatic
  alias VintageNetMobile.Modem.Automatic.Discovery
  alias VintageNet.Interface.RawConfig

  test "create LTE configuration" do
    input = %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: Automatic,
        service_providers: [%{apn: "choosethislteitissafe"}, %{apn: "wireless.twilio.com"}]
      }
    }

    # RawConfig that will be passed to the discovered modem
    base_raw_config = %RawConfig{
      ifname: "ppp0",
      type: VintageNetMobile,
      source_config: input,
      required_ifnames: ["wwan0"],
      up_cmds: [],
      down_cmds: [],
      files: [],
      child_specs: []
    }

    output = %RawConfig{
      ifname: "ppp0",
      type: VintageNetMobile,
      source_config: input,
      required_ifnames: ["wwan0"],
      up_cmds: [
        {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]}
      ],
      down_cmds: [
        {:fun, VintageNet.PropertyTable, :clear_prefix,
         [VintageNet, ["interface", "ppp0", "mobile"]]}
      ],
      files: [],
      child_specs: [
        {Discovery, [raw_config: base_raw_config]}
      ]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end
end
