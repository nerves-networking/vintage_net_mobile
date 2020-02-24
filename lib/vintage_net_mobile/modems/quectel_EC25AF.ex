defmodule VintageNetMobile.Modems.QuectelEC25AF do
  @behaviour VintageNetMobile.Modem

  alias VintageNetMobile.{ServiceProviders, ATRunner, SignalMonitor, PPPDConfig, Chatscript}
  alias VintageNet.Interface.RawConfig

  @impl true
  def specs() do
    [{"Quectel EC25-AF", :_}]
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
