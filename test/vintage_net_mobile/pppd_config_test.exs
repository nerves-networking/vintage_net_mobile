defmodule VintageNetMobile.PPPDConfigTest do
  use ExUnit.Case

  alias VintageNet.Interface.RawConfig
  alias VintageNetMobile.PPPDConfig

  test "updates the raw config to have the pppd child spec" do
    priv_dir = Application.app_dir(:vintage_net_mobile, "priv")

    raw_config = %RawConfig{
      ifname: "ppp0",
      type: VintageNetMobile,
      source_config: %{},
      required_ifnames: ["wwan0"]
    }

    updated_raw_config =
      PPPDConfig.add_child_spec(raw_config, "ttyUSB1", 9600, Utils.default_opts())

    expected_child_specs = [
      {MuonTrap.Daemon,
       [
         "pppd",
         [
           "connect",
           "chat -v -f /tmp/vintage_net/chatscript.ppp0",
           "ttyUSB1",
           "9600",
           "noipdefault",
           "usepeerdns",
           "persist",
           "noauth",
           "nodetach",
           "debug"
         ],
         [env: [{"PRIV_DIR", priv_dir}, {"LD_PRELOAD", Path.join(priv_dir, "pppd_shim.so")}]]
       ]}
    ]

    assert expected_child_specs == updated_raw_config.child_specs
  end
end
