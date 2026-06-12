# SPDX-FileCopyrightText: 2020 Frank Hunleth
# SPDX-FileCopyrightText: 2022 Matt Ludwigs
# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2026 Digit
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VintageNetMobile.Modem.QuectelEG915Q do
  @behaviour VintageNetMobile.Modem

  require Logger

  @moduledoc """
  Quectel EG915Q support

  This modem is a special case, it does not support PPP but instead provides an Ethernet-over-USB interface.
  When configured, AT commands will be sent to the modem to set up the APN and USB network interface.
  The modem will handle the actual connection itself and udhcpc will be used to get an IP address.

  The Quectel EG915Q is an LTE Cat 1 Bis module.

  Example configuration:

  ```elixir
  VintageNet.configure(
    "usb0",
    %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: VintageNetMobile.Modem.QuectelEG915Q,
        service_providers: [%{apn: "super"}]
      }
    }
  )
  ```

  Options:

  * `:modem` - `VintageNetMobile.Modem.QuectelEG915Q`
  * `:service_providers` - A list of service provider information (only `:apn`
    providers are supported)
  * `:at_tty` - A tty for sending AT commands on. This defaults to `"ttyUSB2"`
    which works unless other USB serial devices cause Linux to set it to
    something different.

  If multiple service providers are configured, this implementation only
  attempts to connect to the first one.
  """

  alias VintageNet.Command
  alias VintageNetMobile.ModemECM
  alias VintageNetMobile.{CellMonitor, ExChat, ModemInfo, SignalMonitor}
  alias VintageNetMobile.Modem.Utils

  @impl VintageNetMobile.Modem
  def normalize(config) do
    config
    |> Utils.require_a_service_provider()
  end

  @impl VintageNetMobile.Modem
  def add_raw_config(raw_config, %{vintage_net_mobile: mobile} = _config, _opts) do
    ifname = raw_config.ifname
    at_tty = Map.get(mobile, :at_tty, "ttyUSB2")
    {:ok, hostname} = :inet.gethostname()

    child_specs = [
      {ExChat, [tty: at_tty, speed: 9600]},
      {ModemECM, [ifname: ifname, tty: at_tty, apn: hd(mobile.service_providers).apn]},
      {SignalMonitor, [ifname: ifname, tty: at_tty]},
      {CellMonitor, [ifname: ifname, tty: at_tty]},
      {ModemInfo, [ifname: ifname, tty: at_tty]},
      Supervisor.child_spec(
        {VintageNet.Interface.IfupDaemon,
         [
           ifname: ifname,
           command: "udhcpc",
           args: [
             "-f",
             "-i",
             ifname,
             "-x",
             "hostname:#{hostname}",
             "-s",
             BEAMNotify.bin_path()
           ],
           opts:
             Command.add_muon_options(
               stderr_to_stdout: true,
               log_output: :debug,
               log_prefix: "udhcpc(#{ifname}): ",
               env: BEAMNotify.env(name: "vintage_net_comm", report_env: true)
             )
         ]},
        id: :udhcpc
      ),
      {VintageNet.Connectivity.InternetChecker, ifname}
    ]

    Logger.info("#{inspect(raw_config)}")

    new_up_cmds = raw_config.up_cmds ++ [{:run, "ip", ["link", "set", ifname, "up"]}]

    new_down_cmds =
      raw_config.down_cmds ++
        [
          {:run_ignore_errors, "ip", ["addr", "flush", "dev", ifname, "label", ifname]},
          {:run, "ip", ["link", "set", ifname, "down"]}
        ]

    %{raw_config | up_cmds: new_up_cmds, down_cmds: new_down_cmds}

    %{
      raw_config
      | child_specs: child_specs,
        up_cmds: new_up_cmds,
        down_cmds: new_down_cmds
    }
  end
end
