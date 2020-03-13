defmodule VintageNetMobile.Modem.QuectelBG96 do
  @behaviour VintageNetMobile.Modem

  @moduledoc """
  Quectel BG96 support

  The Quectel BG96 is an LTE Cat M1/Cat NB1/EGPRS module. Here's an example
  configuration:

  ```elixir
  VintageNet.configure(
    "ppp0",
    %{
      type: VintageNetMobile,
      modem: VintageNetMobile.Modem.QuectelBG96,
      service_providers: [%{apn: "super"}]
    }
  )
  ```

  If multiple service providers are configured, this implementation only
  attempts to connect to the first one.

  ## Required Linux kernel options

  * CONFIG_USB_SERIAL=m
  * CONFIG_USB_SERIAL_WWAN=m
  * CONFIG_USB_SERIAL_OPTION=m
  * CONFIG_USB_WDM=m
  * CONFIG_USB_NET_QMI_WWAN=m
  """

  # To force LTE only:
  # ```
  # at+qcfg="nwscanmode",3,1
  # ```
  #
  # To read which Radio Access Technology (RAT) is currently set:
  #
  # ```
  # at+qcfg="nwscanmode"
  # ```
  #
  # To disable Cat NB1 (should do this if in US):
  #
  # ```
  # at+qcfg="iotopmode",0,1
  # ```
  #
  # To enable Cat NB1:
  #
  # ```
  # at+qcfg="iotopmode",1,1
  # ```
  #
  # To enable trying both Cat NB1 and Cat M1:
  #
  # ```
  # at+qcfg="iotopmode",2,1
  # ```

  alias VintageNet.Interface.RawConfig
  alias VintageNetMobile.{ATRunner, SignalMonitor, PPPDConfig, Chatscript}

  @impl true
  def normalize(config) do
    modem_opts = Map.get(config, :modem_opts, %{})
    %{config | modem_opts: modem_opts}
  end

  @impl true
  def add_raw_config(raw_config, config, opts) do
    ifname = raw_config.ifname

    files = [{Chatscript.path(ifname, opts), Chatscript.default(config.service_providers)}]

    child_specs = [
      {ATRunner, [tty: "ttyUSB2", speed: 9600]},
      {SignalMonitor, [ifname: ifname, tty: "ttyUSB2"]}
    ]

    %RawConfig{
      raw_config
      | files: files,
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
  def validate_service_providers([]), do: {:error, :empty}
  def validate_service_providers(_), do: :ok
end
