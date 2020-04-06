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
      vintage_net_mobile: %{
        modem: VintageNetMobile.Modem.QuectelBG96,
        service_providers: [%{apn: "super"}]
      }
    }
  )
  ```

  If multiple service providers are configured, this implementation only
  attempts to connect to the first one.

  The following modem-specific keys are also supported in the
  `:vintage_net_mobile` map:

  * `:scan` - Set this to the order that radio access technologies should be
    attempted when trying to connect. For example, `[:lte_cat_m1, :gsm]`
    would prevent the modem from trying LTE Cat NB1 and potentially save some
    time if you're guaranteed to not have Cat NB1 service.

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

  @impl true
  def normalize(config) do
    config
    |> Utils.require_a_service_provider()
    |> normalize_mobile_opts()
  end

  defp normalize_mobile_opts(%{vintage_net_mobile: mobile} = config) do
    new_mobile =
      mobile
      |> normalize_scan()

    %{config | vintage_net_mobile: new_mobile}
  end

  defp normalize_scan(%{scan: rat_list} = mobile) when is_list(rat_list) do
    supported_list = [:lte_cat_m1, :lte_cat_nb1, :gsm]
    ok_rat_list = Enum.filter(rat_list, fn rat -> rat in supported_list end)

    if ok_rat_list == [] do
      raise ArgumentError,
            "Check your `:scan` list for technologies supported by the BG96: #{
              inspect(supported_list)
            } "
    end

    %{mobile | scan: ok_rat_list}
  end

  defp normalize_scan(mobile), do: mobile

  @impl true
  def add_raw_config(raw_config, %{vintage_net_mobile: mobile} = _config, opts) do
    ifname = raw_config.ifname

    files = [
      {Chatscript.path(ifname, opts), chatscript(mobile)}
    ]

    tty = "ttyUSB2"

    child_specs = [
      {ExChat, [tty: tty, speed: 9600]},
      {SignalMonitor, [ifname: ifname, tty: tty]},
      {CellMonitor, [ifname: ifname, tty: tty]},
      {ModemInfo, [ifname: ifname, tty: tty]}
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

  defp chatscript(mobile) do
    pdp_index = 1

    [
      Chatscript.prologue(),
      Chatscript.set_pdp_context(pdp_index, hd(mobile.service_providers)),
      script_additions(mobile),
      Chatscript.connect(pdp_index)
    ]
    |> IO.iodata_to_binary()
  end

  defp script_additions(nil), do: []

  defp script_additions(mobile) when is_map(mobile) do
    [
      scan_additions(Map.get(mobile, :scan))
    ]
  end

  defp scan_additions(nil) do
    # Reset to the factory default modes and search sequence
    scan_additions([:lte_cat_m1, :lte_cat_nb1, :gsm])
  end

  defp scan_additions(scan_list) when is_list(scan_list) do
    # This sets the sequence as specified and resets nwscanmode and iotop to be permissive
    [
      "OK AT+QCFG=\"nwscanseq\",",
      Enum.map(scan_list, &scan_to_nwscanseq/1),
      "\n",
      "OK AT+QCFG=\"nwscanmode\",",
      scan_to_nwscanmode(scan_list),
      "\n",
      "OK AT+QCFG=\"iotopmode\",",
      scan_to_iotopmode(scan_list),
      "\n"
    ]
  end

  defp scan_to_nwscanseq(:gsm), do: "01"
  defp scan_to_nwscanseq(:lte_cat_m1), do: "02"
  defp scan_to_nwscanseq(:lte_cat_nb1), do: "03"

  defp scan_to_nwscanmode(scan_list) do
    has_gsm = Enum.member?(scan_list, :gsm)
    has_lte = Enum.member?(scan_list, :lte_cat_m1) or Enum.member?(scan_list, :lte_cat_nb1)

    cond do
      has_gsm and has_lte -> "0"
      has_gsm -> "1"
      has_lte -> "3"
      true -> "0"
    end
  end

  defp scan_to_iotopmode(scan_list) do
    has_m1 = Enum.member?(scan_list, :lte_cat_m1)
    has_nb1 = Enum.member?(scan_list, :lte_cat_nb1)

    cond do
      has_m1 and has_nb1 -> "2"
      has_nb1 -> "1"
      true -> "0"
    end
  end
end
