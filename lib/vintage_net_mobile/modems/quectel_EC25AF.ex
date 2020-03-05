defmodule VintageNetMobile.Modems.QuectelEC25AF do
  @moduledoc """
  Modem support the Quectel EC25-AF

  ```elixir
  config :vintage_net,
  config: [
    {"ppp0",
     %{
       type: VintageNetMobile,
       modem: VintageNetMobile.Modems.Quectel25AF,
       service_providers: ["freelte"]
     }}
  ]
  ```

  This modem only allows for one service provider.
  """

  @behaviour VintageNetMobile.Modem

  alias VintageNetMobile.{ATRunner, SignalMonitor, PPPDConfig, Chatscript}
  alias VintageNet.Interface.RawConfig

  @impl true
  def add_raw_config(raw_config, config, opts) do
    ifname = raw_config.ifname

    [apn] = config.service_providers
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

  @impl true
  def ready() do
    if File.exists?("/dev/ttyUSB3") do
      :ok
    else
      {:error, :missing_usb_modem}
    end
  end

  @impl true
  def validate_config(config) do
    case config.service_providers do
      [] ->
        {:error, :empty_service_providers}

      [_service_provider] ->
        :ok

      _service_providers ->
        {:error, :max_service_providers}
    end
  end
end
