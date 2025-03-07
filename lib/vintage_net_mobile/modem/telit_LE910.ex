# SPDX-FileCopyrightText: 2022 Matt Ludwigs
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VintageNetMobile.Modem.TelitLE910 do
  @behaviour VintageNetMobile.Modem

  @moduledoc """
  Telit LE910 support

  ```elixir
  VintageNet.configure(
    "ppp0",
    %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: VintageNetMobile.Modem.TelitLE910,
        service_providers: [%{apn: "wireless.twilio.com"}]
      }
    }
  )
  ```

  If multiple service providers are configured, this implementation only
  attempts to connect to the first one.

  Example of supported properties

  ```elixir
  iex> VintageNet.get_by_prefix ["interface", "ppp0"]
  [
  {["interface", "ppp0", "addresses"],
   [
     %{
       address: {100, 79, 181, 147},
       family: :inet,
       netmask: {255, 255, 255, 255},
       prefix_length: 32,
       scope: :universe
     }
   ]},
  {["interface", "ppp0", "config"],
   %{
     type: VintageNetMobile,
     vintage_net_mobile: %{
       modem: VintageNetMobile.Modem.TelitLE910,
       service_providers: [%{apn: "super"}, %{apn: "wireless.twilio.com"}]
     }
   }},
  {["interface", "ppp0", "connection"], :internet},
  {["interface", "ppp0", "hw_path"], "/devices/virtual"},
  {["interface", "ppp0", "lower_up"], true},
  {["interface", "ppp0", "mobile", "cid"], 123098825},
  {["interface", "ppp0", "mobile", "lac"], 32773},
  {["interface", "ppp0", "mobile", "signal_4bars"], 3},
  {["interface", "ppp0", "mobile", "signal_asu"], 19},
  {["interface", "ppp0", "mobile", "signal_dbm"], -75},
  {["interface", "ppp0", "present"], true},
  {["interface", "ppp0", "state"], :configured},
  {["interface", "ppp0", "type"], VintageNetMobile}
  ]
  ```
  """

  alias VintageNet.Interface.RawConfig
  alias VintageNetMobile.{Chatscript, ExChat, PPPDConfig, SignalMonitor}

  @impl VintageNetMobile.Modem
  def normalize(config) do
    config
  end

  @impl VintageNetMobile.Modem
  def add_raw_config(raw_config, %{vintage_net_mobile: mobile} = _config, opts) do
    ifname = raw_config.ifname

    files = [{Chatscript.path(ifname, opts), Chatscript.default(mobile)}]
    at_tty = Map.get(mobile, :at_tty, "ttyUSB2")
    ppp_tty = Map.get(mobile, :ppp_tty, "ttyUSB3")

    child_specs = [
      {ExChat, [tty: at_tty, speed: 9600]},
      {SignalMonitor, [ifname: ifname, tty: at_tty]}
    ]

    %RawConfig{
      raw_config
      | files: files,
        child_specs: child_specs
    }
    |> PPPDConfig.add_child_spec(ppp_tty, 9600, opts)
  end
end
