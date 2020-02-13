defmodule VintageNetLTE.Modems.QuectelBG96 do
  @moduledoc """
  To force LTE only:

  ```
  at+qcfg="nwscanmode",3,1
  ```

  To read which Radio Access Technology (RAT) is currently set:

  ```
  at+qcfg="nwscanmode"
  ```

  To disable Cat NB1 (should do this if in US):

  ```
  at+qcfg="iotopmode",0,1
  ```

  To enable Cat NB1:

  ```
  at+qcfg="iotopmode",1,1
  ```

  To enable trying both Cat NB1 and Cat M1:

  ```
  at+qcfg="iotopmode",2,1
  ```
  """

  @behaviour VintageNetLTE.Modem

  alias VintageNet.Interface.RawConfig
  alias VintageNetLTE.{ATRunner, SignalMonitor, ServiceProviders}

  @impl true
  def specs() do
    # Support all service providers
    [{"Quectel BG96", :_}]
  end

  @impl true
  def add_raw_config(raw_config, config, opts) do
    ifname = raw_config.ifname

    apn = ServiceProviders.apn!(config.service_provider)
    files = [{chatscript_path(ifname, opts), chatscript(apn)}]

    up_cmds = [
      {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]}
    ]

    child_specs = [
      make_pppd_spec(ifname, "ttyUSB3", 9600, opts),
      {ATRunner, [tty: "ttyUSB2", speed: 9600]},
      {SignalMonitor, [ifname: ifname, tty: "ttyUSB2"]}
    ]

    %RawConfig{
      raw_config
      | files: files,
        up_cmds: up_cmds,
        require_interface: false,
        child_specs: child_specs
    }
  end

  defp chatscript(apn) do
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
    OK AT+CGDCONT=1,"IP","#{apn}"

    # ATDT = Attention Dial Tone
    OK ATDT*99***1#

    # Don't send any more strings when it receives the string CONNECT. Module considers the data links as having been set up.
    CONNECT ''
    """
  end

  defp make_pppd_spec(ifname, serial_port, serial_speed, opts) do
    pppd_bin = Keyword.fetch!(opts, :bin_pppd)
    priv_dir = Application.app_dir(:vintage_net_lte, "priv")
    pppd_shim_path = Path.join(priv_dir, "pppd_shim.so")
    pppd_args = make_pppd_args(ifname, serial_port, serial_speed, opts)

    env = [{"PRIV_DIR", priv_dir}, {"LD_PRELOAD", pppd_shim_path}]

    {MuonTrap.Daemon, [pppd_bin, pppd_args, [env: env]]}
  end

  defp make_pppd_args(ifname, serial_port, serial_speed, opts) do
    chat_bin = Keyword.fetch!(opts, :bin_chat)
    cs_path = chatscript_path(ifname, opts)

    serial_speed = Integer.to_string(serial_speed)

    [
      "connect",
      "#{chat_bin} -v -f #{cs_path}",
      serial_port,
      serial_speed,
      "noipdefault",
      "usepeerdns",
      "persist",
      "noauth",
      "nodetach",
      "debug"
    ]
  end

  defp chatscript_path(ifname, opts) do
    Path.join(Keyword.fetch!(opts, :tmpdir), "chatscript.#{ifname}")
  end
end
