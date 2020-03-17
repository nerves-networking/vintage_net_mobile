defmodule VintageNetMobile.Modem.QuectelEC25 do
  @behaviour VintageNetMobile.Modem

  @moduledoc """
  Quectel EC25 support

  The Quectel EC25 is a series of LTE Cat 4 modules. Here's an example
  configuration:

  ```elixir
  m
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

  alias VintageNetMobile.{ExChat, SignalMonitor, PPPDConfig, Chatscript}
  alias VintageNetMobile.Modem.Utils
  alias VintageNet.Interface.RawConfig

  @impl true
  def normalize(config) do
    config
    |> Utils.require_a_service_provider()
  end

  @impl true
  def add_raw_config(raw_config, %{vintage_net_mobile: mobile} = _config, opts) do
    ifname = raw_config.ifname

    files = [{Chatscript.path(ifname, opts), Chatscript.default(mobile.service_providers)}]

    child_specs = [
      {ExChat, [tty: "ttyUSB2", speed: 9600]},
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
      {:error, :missing_usb_modem}
    end
  end
end
