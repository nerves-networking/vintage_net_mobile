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
  alias VintageNetLTE.{ATRunner, SignalMonitor, ServiceProviders, PPPDConfig, Chatscript}

  @impl true
  def specs() do
    # Support all service providers
    [{"Quectel BG96", :_}]
  end

  @impl true
  def add_raw_config(raw_config, config, opts) do
    ifname = raw_config.ifname

    apn = ServiceProviders.apn!(config.service_provider)
    files = [{Chatscript.path(ifname, opts), Chatscript.default(apn)}]

    up_cmds = [
      {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]}
    ]

    child_specs = [
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
    |> PPPDConfig.add_child_spec("ttyUSB3", 9600, opts)
  end
end
