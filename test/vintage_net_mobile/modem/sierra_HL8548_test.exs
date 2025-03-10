# SPDX-FileCopyrightText: 2020 Frank Hunleth
# SPDX-FileCopyrightText: 2020 Justin Schneck
# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2024 Jon Ringle
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VintageNetMobile.Modem.SierraHL8548Test do
  use ExUnit.Case

  alias VintageNet.Interface.RawConfig
  alias VintageNetMobile.Modem.SierraHL8548

  test "creating a configuration" do
    priv_dir = Application.app_dir(:vintage_net_mobile, "priv")

    input = %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: SierraHL8548,
        service_providers: [%{apn: "choosethislteitissafe"}]
      }
    }

    output = %RawConfig{
      ifname: "ppp0",
      type: VintageNetMobile,
      source_config: input,
      required_ifnames: ["wwan0"],
      up_cmds: [
        {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]},
        {:run_ignore_errors, "mkdir", ["-p", "/var/run/pppd/lock"]}
      ],
      down_cmds: [
        {:fun, PropertyTable, :delete_matches, [VintageNet, ["interface", "ppp0", "mobile"]]}
      ],
      files: [
        {"/tmp/vintage_net/chatscript.ppp0",
         """
         ABORT 'BUSY'
         ABORT 'NO CARRIER'
         ABORT 'NO DIALTONE'
         ABORT 'NO DIAL TONE'
         ABORT 'NO ANSWER'
         ABORT 'DELAYED'
         TIMEOUT 10
         REPORT CONNECT
         "" +++
         "" AT
         OK ATH
         OK ATZ
         OK ATQ0
         OK AT+CGDCONT=1,"IP","choosethislteitissafe"
         OK ATDT*99***1#
         CONNECT ''
         """}
      ],
      child_specs: [
        {MuonTrap.Daemon,
         [
           "pppd",
           [
             "connect",
             "chat -v -f /tmp/vintage_net/chatscript.ppp0",
             "ttyACM4",
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
        {VintageNetMobile.ExChat, [tty: "ttyACM3", speed: 115_200]},
        {VintageNetMobile.SignalMonitor, [ifname: "ppp0", tty: "ttyACM3"]}
      ]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end
end
