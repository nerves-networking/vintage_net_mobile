defmodule VintageNetMobile.Modem.QuectelEC25 do
  @behaviour VintageNetMobile.Modem

  @moduledoc """
  Quectel EC25 support

  The Quectel EC25 is a series of LTE Cat 4 modules. Here's an example
  configuration:

  ```elixir
  {"ppp0",
   %{
     type: VintageNetMobile,
     modem: "Quectel EC25",
     service_providers: [%{apn: "super"}, %{apn: "wireless.twilio.com"}]
   }}
  ```
  """

  alias VintageNetMobile.{ATRunner, SignalMonitor, PPPDConfig, Chatscript}
  alias VintageNet.Interface.RawConfig

  @impl true
  def specs() do
    [{"Quectel EC25", :_}]
  end

  @impl true
  def add_raw_config(raw_config, config, opts) do
    ifname = raw_config.ifname

    files = [{Chatscript.path(ifname, opts), Chatscript.default(config.service_providers)}]

    up_cmds = [
      {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]}
    ]

    child_specs = [
      {ATRunner, [tty: "ttyUSB2", speed: 9600]},
      {SignalMonitor, [ifname: ifname, tty: "ttyUSB2"]}
    ]

    %RawConfig{
      raw_config
      | files: files,
        up_cmds: up_cmds,
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

  @impl true
  def validate_service_providers([]), do: {:error, :empty}
  def validate_service_providers(_), do: :ok
end
