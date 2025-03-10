# SPDX-FileCopyrightText: 2020 Frank Hunleth
# SPDX-FileCopyrightText: 2020 Matt Ludwigs
# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2024 Jon Ringle
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VintageNetMobile.Modem.QuectelEC25Test do
  use ExUnit.Case

  alias VintageNet.Interface.RawConfig
  alias VintageNetMobile.Modem.QuectelEC25

  test "create an LTE configuration" do
    priv_dir = Application.app_dir(:vintage_net_mobile, "priv")

    input = %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: QuectelEC25,
        service_providers: [%{apn: "choosethislteitissafe"}, %{apn: "wireless.twilio.com"}]
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
             "ttyUSB3",
             "9600",
             "noipdefault",
             "usepeerdns",
             "persist",
             "noauth",
             "nodetach",
             "debug"
           ],
           [env: [{"PRIV_DIR", priv_dir}, {"LD_PRELOAD", Path.join(priv_dir, "pppd_shim.so")}]]
         ]},
        {VintageNetMobile.ExChat, [tty: "ttyUSB2", speed: 9600]},
        {VintageNetMobile.SignalMonitor, [ifname: "ppp0", tty: "ttyUSB2"]},
        {VintageNetMobile.CellMonitor, [ifname: "ppp0", tty: "ttyUSB2"]}
      ]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end

  test "non-default tty ports" do
    priv_dir = Application.app_dir(:vintage_net_mobile, "priv")

    input = %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: QuectelEC25,
        service_providers: [%{apn: "choosethislteitissafe"}, %{apn: "wireless.twilio.com"}],
        at_tty: "ttyUSB5",
        ppp_tty: "ttyUSB6"
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
             "ttyUSB6",
             "9600",
             "noipdefault",
             "usepeerdns",
             "persist",
             "noauth",
             "nodetach",
             "debug"
           ],
           [env: [{"PRIV_DIR", priv_dir}, {"LD_PRELOAD", Path.join(priv_dir, "pppd_shim.so")}]]
         ]},
        {VintageNetMobile.ExChat, [tty: "ttyUSB5", speed: 9600]},
        {VintageNetMobile.SignalMonitor, [ifname: "ppp0", tty: "ttyUSB5"]},
        {VintageNetMobile.CellMonitor, [ifname: "ppp0", tty: "ttyUSB5"]}
      ]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end
end
