defmodule VintageNetMobile.Modem.SierraHL8548 do
  @moduledoc """
  Sierra Wireless HL8548 modem

  https://source.sierrawireless.com/resources/airprime/hardware_specs_user_guides/airprime_hl8548_and_hl8548-g_product_technical_specification/

  The Sierra Wireless HL8548 is an industrial grade Embedded Wireless Module
  that provides voice and data connectivity on GPRS, EDGE, WCDMA, HSDPA and
  HSUPA networks.

  This modem supports dual sim selection. You can enable this feature by
  passing `sim_select: mode` in the configuration.

  Here are the possible options:

  ```text
  0 Disable SIM selection.
  1 Force to select the first external SIM. The presence of a second external
    SIM will be ignored.
  2 Force to select the second external SIM. The presence of a first external
    SIM will be ignored.
  3 Select the first external SIM if present else select the second external SIM
  4 Read the SIM presence status
  ```

  Here's an example configuration:

  ```elixir
  VintageNet.configure(
    "ppp0",
    %{
      type: VintageNetMobile,
      sim_select: 3,
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

    files = [{Chatscript.path(ifname, opts), chatscript(mobile)}]

    child_specs = [
      {ExChat, [tty: "ttyACM3", speed: 115_200]},
      {SignalMonitor, [ifname: ifname, tty: "ttyACM3"]}
    ]

    %RawConfig{
      raw_config
      | files: files,
        require_interface: false,
        child_specs: child_specs
    }
    |> PPPDConfig.add_child_spec("ttyACM4", 115_200, opts)
  end

  @impl true
  def ready() do
    if File.exists?("/dev/ttyACM4") do
      :ok
    else
      {:error, :missing_modem}
    end
  end

  defp chatscript(mobile) do
    pdp_index = 1

    [
      Chatscript.prologue(),
      sim_select(mobile),
      Chatscript.set_pdp_context(pdp_index, hd(mobile.service_providers)),
      Chatscript.connect(pdp_index)
    ]
    |> IO.iodata_to_binary()
  end

  defp sim_select(%{sim_select: sim_select}) do
    """
    OK AT+KSIMSEL=#{sim_select}
    """
  end

  defp sim_select(_), do: ""
end
