defmodule VintageNetMobile.Modem.QuectelBG96Test do
  use ExUnit.Case

  alias VintageNet.Interface.RawConfig
  alias VintageNetMobile.Modem.QuectelBG96

  test "normalize works with minimal options" do
    input = %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: QuectelBG96,
        service_providers: [%{apn: "m1_service"}]
      }
    }

    assert input == QuectelBG96.normalize(input)
  end

  test "create an LTE configuration" do
    priv_dir = Application.app_dir(:vintage_net_mobile, "priv")

    input = %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: QuectelBG96,
        service_providers: [%{apn: "m1_service"}]
      }
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
         OK AT+CGDCONT=1,"IP","m1_service"
         OK AT+QCFG=\"nwscanseq\",020301
         OK AT+QCFG=\"nwscanmode\",0
         OK AT+QCFG=\"iotopmode\",2
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
        {VintageNetMobile.CellMonitor, [ifname: "ppp0", tty: "ttyUSB2"]},
        {VintageNetMobile.ModemInfo, [ifname: "ppp0", tty: "ttyUSB2"]}
      ]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end

  test "non-default tty ports" do
    priv_dir = Application.app_dir(:vintage_net_mobile, "priv")

    input = %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: QuectelBG96,
        service_providers: [%{apn: "m1_service"}],
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
        {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]}
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
         OK AT+CGDCONT=1,"IP","m1_service"
         OK AT+QCFG=\"nwscanseq\",020301
         OK AT+QCFG=\"nwscanmode\",0
         OK AT+QCFG=\"iotopmode\",2
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
        {VintageNetMobile.CellMonitor, [ifname: "ppp0", tty: "ttyUSB5"]},
        {VintageNetMobile.ModemInfo, [ifname: "ppp0", tty: "ttyUSB5"]}
      ]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end

  test "restrict to LTE Cat M1-only" do
    priv_dir = Application.app_dir(:vintage_net_mobile, "priv")

    input = %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: QuectelBG96,
        service_providers: [%{apn: "m1_service"}],
        scan: [:lte_cat_m1]
      }
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
         OK AT+CGDCONT=1,"IP","m1_service"
         OK AT+QCFG="nwscanseq",02
         OK AT+QCFG="nwscanmode",3
         OK AT+QCFG="iotopmode",0
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
        {VintageNetMobile.CellMonitor, [ifname: "ppp0", tty: "ttyUSB2"]},
        {VintageNetMobile.ModemInfo, [ifname: "ppp0", tty: "ttyUSB2"]}
      ]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end

  test "normalize filters unsupported rats" do
    input = %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: QuectelBG96,
        service_providers: [%{apn: "m1_service"}],
        scan: [:lte_cat_m1, :gsm, :lte]
      }
    }

    output = %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: QuectelBG96,
        scan: [:lte_cat_m1, :gsm],
        service_providers: [%{apn: "m1_service"}]
      }
    }

    assert VintageNetMobile.normalize(input) == output
  end

  test "normalize raises if no supported rats" do
    input = %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: QuectelBG96,
        scan: [:lte],
        service_providers: [%{apn: "m1_service"}]
      }
    }

    assert_raise ArgumentError, fn -> VintageNetMobile.normalize(input) end
  end

  test "requires one provider" do
    input = %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: QuectelBG96,
        service_providers: []
      }
    }

    assert_raise ArgumentError, fn -> QuectelBG96.normalize(input) end
  end

  test "requires provider to have an apn" do
    input = %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: QuectelBG96,
        service_providers: [%{not_apn: "asdf"}]
      }
    }

    assert_raise ArgumentError, fn -> QuectelBG96.normalize(input) end
  end
end
