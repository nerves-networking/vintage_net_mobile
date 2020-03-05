defmodule VintageNetMobile.Modems.QuectelBG96 do
  @moduledoc """
  Modem support the Quectel BG96

  ```elixir
  config :vintage_net,
  config: [
    {"ppp0",
     %{
       type: VintageNetMobile,
       modem: VintageNetMobile.Modems.QuectelBG96,
       service_providers: ["freelte"]
     }}
  ]
  ```

  This modem only allows for one service provider.

  ### Helpful AT commands

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

  @behaviour VintageNetMobile.Modem

  alias VintageNet.Interface.RawConfig
  alias VintageNetMobile.{ATRunner, SignalMonitor, PPPDConfig, Chatscript}

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
      {:error, :missing_modem}
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
