defmodule VintageNetLTETest do
  use ExUnit.Case

  alias VintageNet.Interface.RawConfig
  alias VintageNetLTE.Modems.MockModem
  alias VintageNetLTE.{ATRunner, SignalMonitor}

  test "create an LTE configuration" do
    priv_dir = Application.app_dir(:vintage_net_lte, "priv")
    input = %{type: VintageNetLTE, modem: MockModem, provider: %{}}

    output = %RawConfig{
      ifname: "ppp0",
      type: VintageNetLTE,
      source_config: input,
      require_interface: false,
      up_cmds: [
        {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]}
      ],
      files: [{"/tmp/vintage_net/chatscript.ppp0", ""}],
      child_specs: [
        {MuonTrap.Daemon,
         [
           "pppd",
           [
             "connect",
             "chat -v -f /tmp/vintage_net/chatscript.ppp0",
             "/dev/null",
             "115200",
             "noipdefault",
             "usepeerdns",
             "persist",
             "noauth",
             "nodetach",
             "debug"
           ],
           [env: [{"PRIV_DIR", priv_dir}, {"LD_PRELOAD", Path.join(priv_dir, "pppd_shim.so")}]]
         ]},
        {ATRunner, [tty: "null", speed: 115_200]},
        {SignalMonitor, [ifname: "ppp0", tty: "null"]}
      ]
    }

    assert output == VintageNetLTE.to_raw_config("ppp0", input, Utils.default_opts())
  end
end
