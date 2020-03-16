defmodule VintageNetMobile.Modem.UbloxTOBYL2 do
  @behaviour VintageNetMobile.Modem

  @moduledoc """
  ublox TOBY-L2 support

  The ublox TOBY-L2 is a series of LTE Cat 4 modules with HSPA+ and/or 2G
  fallback. Here's an example configuration:

  ```elixir
  VintageNet.configure(
    "ppp0",
    %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: VintageNetMobile.Modem.UbloxTOBYL2,
        service_providers: [
          %{apn: "lte-apn", usage: :eps_bearer},
          %{apn: "old-apn", usage: :pdp}
        ]
      }
    }
  )
  ```

  This implementation currently requires APNs to be annotated for whether
  they are to be used on LTE (`:eps_bearer`) or on UMTS/GPRS (`:pdp`).

  ## Required Linux kernel options

  * CONFIG_USB_SERIAL=m
  * CONFIG_USB_SERIAL_WWAN=m
  * CONFIG_USB_SERIAL_OPTION=m
  """

  # Useful references:
  #  * AT commands - https://www.u-blox.com/en/docs/UBX-13002752

  alias VintageNetMobile.{ExChat, SignalMonitor, PPPDConfig, Chatscript}
  alias VintageNet.Interface.RawConfig

  @impl true
  def normalize(config), do: config

  @impl true
  def add_raw_config(raw_config, %{vintage_net_mobile: mobile} = _config, opts) do
    ifname = raw_config.ifname

    files = [{Chatscript.path(ifname, opts), chatscript(mobile.service_providers)}]

    child_specs = [
      {ExChat, [tty: "ttyACM1", speed: 115_200]},
      {SignalMonitor, [ifname: ifname, tty: "ttyACM1"]}
    ]

    %RawConfig{
      raw_config
      | files: files,
        require_interface: false,
        child_specs: child_specs
    }
    |> PPPDConfig.add_child_spec("ttyACM2", 115_200, opts)
  end

  @impl true
  def ready() do
    if File.exists?("/dev/ttyACM2") do
      :ok
    else
      {:error, :missing_usb_modem}
    end
  end

  defp chatscript(service_providers) do
    lte_provider = eps_bearer(service_providers)
    other_provider = pdp(service_providers)

    [
      Chatscript.prologue(120),
      """
      # Enter airplane mode
      OK AT+CFUN=4

      # Delete existing contexts
      OK AT+CGDEL

      # Define PDP context
      OK AT+UCGDFLT=1,"IP","#{lte_provider.apn}"
      OK AT+CGDCONT=1,"IP","#{other_provider.apn}"

      OK AT+CFUN=1
      """,
      Chatscript.connect()
    ]
    |> IO.iodata_to_binary()
  end

  @impl true
  def validate_service_providers([]), do: {:error, "No service providers"}

  def validate_service_providers(providers) do
    if eps_bearer(providers) != nil and pdp(providers) != nil do
      :ok
    else
      {:error, "Must annotate APNs with their usage (:eps_bearer and :pdp)"}
    end
  end

  defp find_by_usage(service_providers, what) do
    Enum.find(service_providers, &(Map.get(&1, :usage) == what))
  end

  defp eps_bearer(service_providers) do
    find_by_usage(service_providers, :eps_bearer)
  end

  defp pdp(service_providers) do
    find_by_usage(service_providers, :pdp)
  end
end
