defmodule VintageNetMobile.Modem.UbloxTOBYL2Test do
  use ExUnit.Case

  alias VintageNetMobile.Modem.UbloxTOBYL2
  alias VintageNet.Interface.RawConfig

  test "create an LTE configuration" do
    priv_dir = Application.app_dir(:vintage_net_mobile, "priv")

    input = %{
      type: VintageNetMobile,
      modem: UbloxTOBYL2,
      service_providers: [
        %{type: "4g", apn: "lte-apn"},
        %{type: "3g", apn: "old-apn"}
      ]
    }

    output = %RawConfig{
      child_specs: [
        "Elixir.MuonTrap.Daemon": [
          "pppd",
          [
            "connect",
            "chat -v -f /tmp/vintage_net/chatscript.ppp0",
            "ttyACM2",
            "115200",
            "noipdefault",
            "usepeerdns",
            "persist",
            "noauth",
            "nodetach",
            "debug"
          ],
          [env: [{"PRIV_DIR", priv_dir}, {"LD_PRELOAD", Path.join(priv_dir, "pppd_shim.so")}]]
        ],
        "Elixir.VintageNetMobile.ATRunner": [tty: "ttyACM1", speed: 115_200],
        "Elixir.VintageNetMobile.SignalMonitor": [ifname: "ppp0", tty: "ttyACM1"]
      ],
      cleanup_files: '',
      down_cmd_millis: 5000,
      down_cmds: '',
      files: [
        {
          "/tmp/vintage_net/chatscript.ppp0",
          "# Exit execution if module receives any of the following strings:\nABORT 'BUSY'\nABORT 'NO CARRIER'\nABORT 'NO DIALTONE'\nABORT 'NO DIAL TONE'\nABORT 'NO ANSWER'\nABORT 'DELAYED'\nTIMEOUT 120\nREPORT CONNECT\n\n\"\" +++\n\n# Module will send the string AT regardless of the string it receives\n\"\" AT\n\n# Instructs the modem to disconnect from the line, terminating any call in progress. All of the functions of the command shall be completed before the modem returns a result code.\nOK ATH\n\n# Instructs the modem to set all parameters to the factory defaults.\nOK ATZ\n\n# Enter airplane mode\nOK AT+CFUN=4\n\n# Delete existing contextx\nOK AT+CGDEL\n\n# Define PDP context\nOK AT+UCGDFLT=1,\"IP\",\"lte-apn\"\nOK AT+CGDCONT=1,\"IP\",\"old-apn\"\n\nOK AT+CFUN=1\n\n# Enter PPPD mode\nOK ATD*99***1#\n\nCONNECT ''\n"
        }
      ],
      ifname: "ppp0",
      require_interface: false,
      restart_strategy: :one_for_all,
      retry_millis: 30000,
      source_config: %{
        modem: VintageNetMobile.Modem.UbloxTOBYL2,
        service_providers: [%{apn: "lte-apn", type: "4g"}, %{apn: "old-apn", type: "3g"}],
        type: VintageNetMobile
      },
      type: VintageNetMobile,
      up_cmd_millis: 5000,
      up_cmds: [
        {:fun, VintageNetMobile.Modem.UbloxTOBYL2, :ready, ''},
        {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]}
      ]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end
end
