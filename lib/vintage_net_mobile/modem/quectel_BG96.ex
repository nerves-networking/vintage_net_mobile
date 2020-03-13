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
      modem_opts: %{},
      service_providers: [%{apn: "super"}]
    }
  )
  ```

  If multiple service providers are configured, this implementation only
  attempts to connect to the first one.

  The `:modem_opts` key is optional and the following device-specific options
  are supported:

  * `:scan` - Set this to the order that radio access technologies should be
    attempted when trying to connect. For example, `[:lte_cat_m1, :gsm]`
    would prevent the modem from trying LTE Cat NB1 and potentially save some
    time if you're guaranteed to not have Cat NB1 service.

  ## Required Linux kernel options

  * CONFIG_USB_SERIAL=m
  * CONFIG_USB_SERIAL_WWAN=m
  * CONFIG_USB_SERIAL_OPTION=m
  * CONFIG_USB_WDM=m
  * CONFIG_USB_NET_QMI_WWAN=m
  """

  @typedoc """
  Radio Access Technology (RAT)

  These define how to connect to the cellular network.
  """
  @type rat :: :gsm | :td_scdma | :wcdma | :lte | :cdma | :lte_cat_nb1 | :lte_cat_m1

  alias VintageNet.Interface.RawConfig
  alias VintageNetMobile.{ATRunner, SignalMonitor, PPPDConfig, Chatscript}

  @impl true
  def normalize(config) do
    modem_opts =
      Map.get(config, :modem_opts, %{})
      |> normalize_modem_opts()

    %{config | modem_opts: modem_opts}
  end

  defp normalize_modem_opts(modem_opts) do
    scan = normalize_scan(Map.get(modem_opts, :scan))
    %{scan: scan}
  end

  defp normalize_scan(nil), do: nil

  defp normalize_scan(rat_list) when is_list(rat_list) do
    supported_list = [:lte_cat_m1, :lte_cat_nb, :gsm]
    ok_rat_list = Enum.filter(rat_list, fn rat -> rat in supported_list end)

    if ok_rat_list == [] do
      raise ArgumentError,
            "Check your `:scan` list for technologies supported by the BG96: #{
              inspect(supported_list)
            } "
    end

    ok_rat_list
  end

  @impl true
  def add_raw_config(raw_config, config, opts) do
    ifname = raw_config.ifname

    files = [
      {Chatscript.path(ifname, opts),
       chatscript(config.service_providers, Map.get(config, :modem_opts))}
    ]

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

  defp chatscript(service_providers, modem_opts) do
    pdp_index = 1

    [
      Chatscript.prologue(),
      Chatscript.set_pdp_context(pdp_index, hd(service_providers)),
      script_additions(modem_opts),
      Chatscript.connect(pdp_index)
    ]
    |> IO.iodata_to_binary()
  end

  defp script_additions(nil), do: []

  defp script_additions(modem_opts) when is_map(modem_opts) do
    [
      scan_additions(Map.get(modem_opts, :scan))
    ]
  end

  defp scan_additions(scan_list) do
    # This sets the sequence as specified and resets nwscanmode and iotop to be permissive
    [
      "OK AT+QCFG=\"nwscanseq\",",
      Enum.map(scan_list, &scan_to_num/1),
      "\n",
      "OK AT+QCFG=\"nwscanmode\",0\n",
      "OK AT+QCFG=\"iotopmode\",2\n"
    ]
  end

  defp scan_to_num(:gsm), do: "01"
  defp scan_to_num(:lte_cat_m1), do: "02"
  defp scan_to_num(:lte_cat_nb1), do: "03"
end
