defmodule VintageNetMobile.Modems.UbloxTOBYL2 do
  @behaviour VintageNetMobile.Modem

  alias VintageNetMobile.{ATRunner, SignalMonitor, PPPDConfig, Chatscript}
  alias VintageNet.Interface.RawConfig

  require Logger

  @impl true
  def specs() do
    [{"u-blox TOBY-L2", :_}]
  end

  @impl true
  def add_raw_config(raw_config, config, opts) do
    ifname = raw_config.ifname

    files = [{Chatscript.path(ifname, opts), chatscript(config.service_providers)}]

    up_cmds = [
      {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]}
    ]

    child_specs = [
      {ATRunner, [tty: "ttyACM1", speed: 115_200]},
      {SignalMonitor, [ifname: ifname, tty: "ttyACM1"]}
    ]

    %RawConfig{
      raw_config
      | files: files,
        up_cmds: up_cmds,
        require_interface: false,
        child_specs: child_specs
    }
    |> PPPDConfig.add_child_spec("ttyACM2", 115_200, opts)
  end

  @impl true
  def ready() do
    if File.exists?("/dev/ttyACM2") do
      :ok
    else
      {:error, :missing_usb_modem}
    end
  end

  def chatscript(service_providers) do
    apn_4g = Enum.find(service_providers, &(&1.type == "4g"))
    apn_3g = Enum.find(service_providers, &(&1.type == "3g"))

    """
    # Exit execution if module receives any of the following strings:
    ABORT 'BUSY'
    ABORT 'NO CARRIER'
    ABORT 'NO DIALTONE'
    ABORT 'NO DIAL TONE'
    ABORT 'NO ANSWER'
    ABORT 'DELAYED'
    TIMEOUT 120
    REPORT CONNECT

    "" +++

    # Module will send the string AT regardless of the string it receives
    "" AT

    # Instructs the modem to disconnect from the line, terminating any call in progress. All of the functions of the command shall be completed before the modem returns a result code.
    OK ATH

    # Instructs the modem to set all parameters to the factory defaults.
    OK ATZ

    # Enter airplane mode
    OK AT+CFUN=4

    # Delete existing contextx
    OK AT+CGDEL

    # Define PDP context
    OK AT+UCGDFLT=1,"IP","#{apn_4g.apn}"
    OK AT+CGDCONT=1,"IP","#{apn_3g.apn}"

    OK AT+CFUN=1

    # Enter PPPD mode
    OK ATD*99***1#

    CONNECT ''
    """
  end

  @impl true
  def validate_service_providers([]), do: {:error, :empty}
  def validate_service_providers(_), do: :ok
end
