defmodule VintageNetMobile.Modem.HuaweiE3372 do
  @behaviour VintageNetMobile.Modem

  alias VintageNet.Interface.RawConfig
  alias VintageNetMobile.{CellMonitor, Chatscript, ExChat, ModemInfo, PPPDConfig, SignalMonitor}
  alias VintageNetMobile.Modem.Utils


  @moduledoc """
  Huawei E3372 support

  This modem needs a usb modeswitch, the follwing can serve as an example

  ```elixir
  def modemswicth(product_id \\ "14fe") do
      Toolshed.cmd("usb_modeswitch -v 12d1 -p #{product_id} -X")
  end
  ```

  After the mode switch you can connect like with any other modem

  ```elixir
    VintageNet.configure("ppp0", %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: MyApp.Network.HuaweiE3372,
        service_providers: [%{apn: "some apn"}]
      }
    })
  ```

  BEWARE Currently none of the Signal, Cell and Modem monitors are working
  """

  @impl true
  def ready do
    if File.exists?("/dev/ttyUSB0") do
      :ok
    else
      {:error, :modem_not_connected}
    end
  end

  @impl true
  def normalize(config) do
    config
    |> Utils.require_a_service_provider()
  end

  @impl true
  def add_raw_config(raw_config, %{vintage_net_mobile: mobile} = _config, opts) do
    ifname = raw_config.ifname

    files = [
      {Chatscript.path(ifname, opts), chatscript(hd(mobile.service_providers))}
    ]

    tty = "ttyUSB2"

    child_specs = [
      {ExChat, [tty: tty, speed: 115_200]},
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
    |> PPPDConfig.add_child_spec("ttyUSB0", 115_200, opts)
  end

  def chatscript(service_provider) do
    [
      Chatscript.prologue(),
      Chatscript.set_pdp_context(1, service_provider),
      """
      OK ATDT*99#
      CONNECT ''
      """
    ]
    |> IO.iodata_to_binary()
  end
end

