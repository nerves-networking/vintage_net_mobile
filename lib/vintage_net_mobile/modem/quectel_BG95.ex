defmodule VintageNetMobile.Modem.QuectelBG96 do
  @behaviour VintageNetMobile.Modem

  require Logger

  @moduledoc """
  Quectel BG95-M3 support

  The Quectel BG95-M3 is an LTE Cat M1/Cat NB1/EGPRS module that doesn't support
  QMI so triggering off the QMI interface ("wwan0") like the BG96 implementation does
  won't work. Here's an example configuration:

  ```elixir
  VintageNet.configure(
    "ppp0",
    %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: VintageNetMobile.Modem.QuectelBG95,
        service_providers: [%{apn: "super"}]
      }
    }
  )
  ```

  Options:

  * `:modem` - `VintageNetMobile.Modem.QuectelBG96`
  * `:service_providers` - A list of service provider information (only `:apn`
    providers are supported)
  * `:at_tty` - A tty for sending AT commands on. This defaults to `"ttyUSB2"`
    which works unless other USB serial devices cause Linux to set it to
    something different.
  * `:ppp_tty` - A tty for the PPP connection. This defaults to `"ttyUSB2"`
    which works unless other USB serial devices cause Linux to set it to
    something different.
  * `:scan` - Set this to the order that radio access technologies should be
    attempted when trying to connect. For example, `[:lte_cat_m1, :gsm]`
    would prevent the modem from trying LTE Cat NB1 and potentially save some
    time if you're guaranteed to not have Cat NB1 service.

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
    {["interface", "ppp0", "mobile", "access_technology"], "CAT-M1"},
    {["interface", "ppp0", "mobile", "band"], "LTE BAND 12"},
    {["interface", "ppp0", "mobile", "channel"], 5110},
    {["interface", "ppp0", "mobile", "cid"], 18677159},
    {["interface", "ppp0", "mobile", "lac"], 4319},
    {["interface", "ppp0", "mobile", "mcc"], 310},
    {["interface", "ppp0", "mobile", "mnc"], 410},
    {["interface", "ppp0", "mobile", "network"], "AT&T"},
    {["interface", "ppp0", "mobile", "signal_4bars"], 4},
    {["interface", "ppp0", "mobile", "signal_asu"], 25},
    {["interface", "ppp0", "mobile", "signal_dbm"], -63},
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

  alias VintageNet.Interface.RawConfig
  alias VintageNetMobile.{CellMonitor, Chatscript, ExChat, ModemInfo, PPPDConfig, SignalMonitor}
  alias VintageNetMobile.Modem.Utils

  @impl VintageNetMobile.Modem
  def normalize(config) do
    config
    |> Utils.require_a_service_provider()
  end

  @impl VintageNetMobile.Modem
  def add_raw_config(raw_config, %{vintage_net_mobile: mobile} = _config, opts) do
    ifname = raw_config.ifname

    files = [{Chatscript.path(ifname, opts), Chatscript.default(mobile)}]
    at_tty = Map.get(mobile, :at_tty, "ttyUSB2")
    ppp_tty = Map.get(mobile, :ppp_tty, "ttyUSB3")

    child_specs = [
      {ExChat, [tty: at_tty, speed: 115_200]}
      # {SignalMonitor, [ifname: ifname, tty: at_tty]},
      # {CellMonitor, [ifname: ifname, tty: at_tty]},
      # {ModemInfo, [ifname: ifname, tty: at_tty]}
    ]

    %RawConfig{
      raw_config
      | files: files,
        child_specs: child_specs,
        required_ifnames: ["ttyUSB2"]
    }
    |> PPPDConfig.add_child_spec(ppp_tty, 115_200, opts)
  end
end
