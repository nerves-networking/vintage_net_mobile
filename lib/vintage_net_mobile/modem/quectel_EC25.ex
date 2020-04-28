defmodule VintageNetMobile.Modem.QuectelEC25 do
  @behaviour VintageNetMobile.Modem

  @moduledoc """
  Quectel EC25 support

  The Quectel EC25 is a series of LTE Cat 4 modules. Here's an example
  configuration:

  ```elixir
  VintageNet.configure(
    "ppp0",
    %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: VintageNetMobile.Modem.QuectelEC25,
        service_providers: [%{apn: "wireless.twilio.com"}]
      }
    }
  )
  ```

  If multiple service providers are configured, this implementation only
  attempts to connect to the first one.

  Example of supported properties:

  ```elixir
  iex> VintageNet.get_by_prefix(["interface", "ppp0"])
  [
    {["interface", "ppp0", "addresses"],
    [
      %{
        address: {10, 64, 64, 64},
        family: :inet,
        netmask: {255, 255, 255, 255},
        prefix_length: 32,
        scope: :universe
      }
    ]},
    {["interface", "ppp0", "connection"], :internet},
    {["interface", "ppp0", "lower_up"], true},
    {["interface", "ppp0", "mobile", "access_technology"], "FDD LTE"},
    {["interface", "ppp0", "mobile", "band"], "LTE BAND 4"},
    {["interface", "ppp0", "mobile", "channel"], 2300},
    {["interface", "ppp0", "mobile", "cid"], 11303407},
    {["interface", "ppp0", "mobile", "lac"], 10234},
    {["interface", "ppp0", "mobile", "mcc"], 360},
    {["interface", "ppp0", "mobile", "mnc"], 200},
    {["interface", "ppp0", "mobile", "network"], "Twilio"},
    {["interface", "ppp0", "mobile", "signal_asu"], 21},
    {["interface", "ppp0", "mobile", "signal_4bars"], 4},
    {["interface", "ppp0", "mobile", "signal_dbm"], -71},
    {["interface", "ppp0", "present"], true},
    {["interface", "ppp0", "state"], :configured},
    {["interface", "ppp0", "type"], VintageNetMobile}
  ]
  ```

  ## Required Linux kernel options

  * CONFIG_USB_SERIAL=m
  * CONFIG_USB_SERIAL_WWAN=m
  * CONFIG_USB_SERIAL_OPTION=m
  * CONFIG_USB_WDM=m
  * CONFIG_USB_NET_QMI_WWAN=m
  """

  alias VintageNetMobile.{ExChat, SignalMonitor, CellMonitor, PPPDConfig, Chatscript}
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

    files = [{Chatscript.path(ifname, opts), Chatscript.default(mobile)}]

    child_specs = [
      {ExChat, [tty: "ttyUSB2", speed: 9600]},
      {SignalMonitor, [ifname: ifname, tty: "ttyUSB2"]},
      {CellMonitor, [ifname: ifname, tty: "ttyUSB2"]}
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
