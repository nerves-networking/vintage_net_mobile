defmodule VintageNetMobile.Modem.UbloxTOBYL2Test do
  use ExUnit.Case

  alias VintageNetMobile.Modem.UbloxTOBYL2
  alias VintageNet.Interface.RawConfig

  test "creating a configuration" do
    priv_dir = Application.app_dir(:vintage_net_mobile, "priv")

    input = %{
      type: VintageNetMobile,
      modem: UbloxTOBYL2,
      service_providers: [
        %{apn: "lte-apn", usage: :eps_bearer},
        %{apn: "old-apn", usage: :pdp}
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
      files: [
        {
          "/tmp/vintage_net/chatscript.ppp0",
          """
          ABORT 'BUSY'
          ABORT 'NO CARRIER'
          ABORT 'NO DIALTONE'
          ABORT 'NO DIAL TONE'
          ABORT 'NO ANSWER'
          ABORT 'DELAYED'
          TIMEOUT 120
          REPORT CONNECT
          "" +++
          "" AT
          OK ATH
          OK ATZ
          OK ATQ0
          # Enter airplane mode
          OK AT+CFUN=4

          # Delete existing contexts
          OK AT+CGDEL

          # Define PDP context
          OK AT+UCGDFLT=1,"IP","lte-apn"
          OK AT+CGDCONT=1,"IP","old-apn"

          OK AT+CFUN=1
          OK ATDT*99***1#
          CONNECT ''
          """
        }
      ],
      ifname: "ppp0",
      require_interface: false,
      restart_strategy: :one_for_all,
      retry_millis: 30000,
      source_config: input,
      type: VintageNetMobile,
      up_cmd_millis: 5000,
      up_cmds: [
        {:fun, VintageNetMobile.Modem.UbloxTOBYL2, :ready, ''},
        {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]}
      ],
      down_cmds: [
        {:fun, VintageNet.PropertyTable, :clear_prefix,
         [VintageNet, ["interface", "ppp0", "mobile"]]}
      ]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end

  test "raises when usage not specified" do
    input = %{
      type: VintageNetMobile,
      modem: UbloxTOBYL2,
      service_providers: [
        %{apn: "lte-apn"},
        %{apn: "old-apn"}
      ]
    }

    assert_raise ArgumentError, fn ->
      VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
    end
  end
end
