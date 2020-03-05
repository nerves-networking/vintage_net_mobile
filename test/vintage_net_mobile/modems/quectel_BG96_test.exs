defmodule VintageNetMobile.Modems.QuectelBG96Test do
  use ExUnit.Case

  alias VintageNetMobile.Modems.QuectelBG96
  alias VintageNet.Interface.RawConfig

  test "create an LTE configuration" do
    priv_dir = Application.app_dir(:vintage_net_mobile, "priv")

    input = %{
      type: VintageNetMobile,
      modem: QuectelBG96,
      service_providers: ["wireless.twilio.com"]
    }

    output = %RawConfig{
      ifname: "ppp0",
      type: VintageNetMobile,
      source_config: input,
      require_interface: false,
      up_cmds: [
        {:fun, QuectelBG96, :ready, []},
        {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]}
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

         "" AT

         OK ATH

         OK ATZ

         OK ATQ0

         OK AT+CGDCONT=1,"IP","wireless.twilio.com"

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
        {VintageNetMobile.ATRunner, [tty: "ttyUSB2", speed: 9600]},
        {VintageNetMobile.SignalMonitor, [ifname: "ppp0", tty: "ttyUSB2"]}
      ]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end

  describe "validating configurations" do
    test "marks no service providers as invalid" do
      config = %{service_providers: []}

      assert {:error, :empty_service_providers} == QuectelBG96.validate_config(config)
    end

    test "marks more than one service providers as invalid" do
      config = %{service_providers: ["one", "two"]}
      assert {:error, :max_service_providers} == QuectelBG96.validate_config(config)
    end

    test "mark one service provider as valid" do
      config = %{service_providers: ["one"]}

      assert :ok = QuectelBG96.validate_config(config)
    end
  end
end
