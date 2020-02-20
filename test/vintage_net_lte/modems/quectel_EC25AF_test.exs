defmodule VintageNetLTE.Modems.QuectelEC25AFTest do
  use ExUnit.Case

  alias VintageNetLTE.Modems.QuectelEC25AF
  alias VintageNet.Interface.RawConfig

  test "returns table entries" do
    assert [{"Quectel EC25-AF", :_}] == QuectelEC25AF.specs()
  end

  test "create an LTE configuration" do
    priv_dir = Application.app_dir(:vintage_net_lte, "priv")
    input = %{type: VintageNetLTE, modem: "Quectel EC25-AF", service_provider: "Twilio"}

    output = %RawConfig{
      ifname: "ppp0",
      type: VintageNetLTE,
      source_config: input,
      require_interface: false,
      up_cmds: [
        {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]}
      ],
      files: [
        {"/tmp/vintage_net/chatscript.ppp0",
         """
         # Exit execution if module receives any of the following strings:
         ABORT 'BUSY'
         ABORT 'NO CARRIER'
         ABORT 'NO DIALTONE'
         ABORT 'NO DIAL TONE'
         ABORT 'NO ANSWER'
         ABORT 'DELAYED'
         TIMEOUT 10
         REPORT CONNECT

         # Module will send the string AT regardless of the string it receives
         "" AT

         # Instructs the modem to disconnect from the line, terminating any call in progress. All of the functions of the command shall be completed before the modem returns a result code.
         OK ATH

         # Instructs the modem to set all parameters to the factory defaults.
         OK ATZ

         # Result codes are sent to the Data Terminal Equipment (DTE).
         OK ATQ0

         # Define PDP context
         OK AT+CGDCONT=1,"IP","wireless.twilio.com"

         # ATDT = Attention Dial Tone
         OK ATDT*99***1#

         # Don't send any more strings when it receives the string CONNECT. Module considers the data links as having been set up.
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
        {VintageNetLTE.ATRunner, [tty: "ttyUSB2", speed: 9600]},
        {VintageNetLTE.SignalMonitor, [ifname: "ppp0", tty: "ttyUSB2"]}
      ]
    }

    assert output == VintageNetLTE.to_raw_config("ppp0", input, Utils.default_opts())
  end
end