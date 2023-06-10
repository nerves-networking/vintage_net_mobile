defmodule VintageNetMobile.Modem.SierraHL8548 do
  @moduledoc """
  Sierra Wireless HL8548 modem

  https://source.sierrawireless.com/resources/airprime/hardware_specs_user_guides/airprime_hl8548_and_hl8548-g_product_technical_specification/

  The Sierra Wireless HL8548 is an industrial grade Embedded Wireless Module
  that provides voice and data connectivity on GPRS, EDGE, WCDMA, HSDPA and
  HSUPA networks.

  Here's an example configuration:

  ```elixir
  VintageNet.configure(
    "ppp0",
    %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: VintageNetMobile.Modem.SierraHL8548,
        service_providers: [%{apn: "BROADBAND"}]
      }
    }
  )
  ```
  """

  # Useful references:
  #  * AT commands - https://source.sierrawireless.com/resources/airprime/software/airprime_hl6_and_hl8_series_at_commands_interface_guide

  @behaviour VintageNetMobile.Modem

  alias VintageNet.Interface.RawConfig
  alias VintageNetMobile.Chatscript
  alias VintageNetMobile.ExChat
  alias VintageNetMobile.Modem.Utils
  alias VintageNetMobile.PPPDConfig
  alias VintageNetMobile.SignalMonitor

  @impl VintageNetMobile.Modem
  def normalize(config) do
    config
    |> Utils.require_a_service_provider()
  end

  @impl VintageNetMobile.Modem
  def add_raw_config(raw_config, %{vintage_net_mobile: mobile} = _config, opts) do
    ifname = raw_config.ifname

    files = [{Chatscript.path(ifname, opts), Chatscript.default(mobile)}]

    child_specs = [
      {ExChat, [tty: "ttyACM3", speed: 115_200]},
      {SignalMonitor, [ifname: ifname, tty: "ttyACM3"]}
    ]

    %RawConfig{
      raw_config
      | files: files,
        child_specs: child_specs
    }
    |> PPPDConfig.add_child_spec("ttyACM4", 115_200, opts)
  end
end
