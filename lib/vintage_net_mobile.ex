# SPDX-FileCopyrightText: 2019 Matt Ludwigs
# SPDX-FileCopyrightText: 2020 Frank Hunleth
# SPDX-FileCopyrightText: 2024 Jon Ringle
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VintageNetMobile do
  @behaviour VintageNet.Technology

  alias VintageNet.Interface.RawConfig

  @moduledoc """
  Use cellular modems with VintageNet

  This module is not intended to be called directly but via calls to `VintageNet`. Here's a
  typical example:

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

  The `:modem` key should be set to your modem implementation. Cellular modems
  tend to be very similar. If `vintage_net_mobile` doesn't support your modem, see
  the customizing section. It may just be a copy/paste away. See your modem
  module for modem-specific options. The following keys are supported by all modems:

  * `:service_providers` - This is a list of service provider information
  * `:chatscript_additions` - This is a string (technically iodata) for custom
     modem initialization.

  The `:service_providers` key should be set to information provided by each of
  your service providers. It is common that this is a list of one item.
  Circumstances may require you to list more than one, though. Additionally, modem
  implementations may require more or less information depending on their
  implementation. (It's possible to hard-code the service provider in the modem
  implementation. In that case, this key isn't used and should be set to an empty
  list. This is useful when your cellular modem provides instructions that
  magically work and the AT commands that they give are confusing.)

  Information for each service provider is a map with some or all of the following
  fields:

  * `:apn` (required) - e.g., `"access_point_name"`
  * `:usage` (optional) - `:eps_bearer` (LTE) or `:pdp` (UMTS/GPRS)

  Your service provider should provide you with the information that you need to
  connect. Often it is just an APN. The Gnome project provides a database of
  [service provider
  information](https://wiki.gnome.org/Projects/NetworkManager/MobileBroadband/ServiceProviders)
  that may also be useful.

  Here's an example with a service provider list:

  ```elixir
    %{
      type: VintageNetMobile,
      modem: your_modem,
      vintage_net_mobile: %{
        service_providers: [
          %{apn: "wireless.twilio.com"}
        ],
        chatscript_additions: "OK AT"
      }
    }
  ```

  ## Custom modems

  `VintageNetMobile` allows you add custom modem implementations if the built-in
  ones don't work for you. See the `VintageNetMobile.Modem` behaviour.

  In order to implement a modem, you will need:

  1. Instructions for connecting to the modem via your Linux. Sometimes this
    involves `usb_modeswitch` or knowing which serial ports the modem exposes.
  2. Example chat scripts. These are lists of `AT` commands and their expected
    responses for configuring the service provider and entering `PPP` mode.
  3. (Optional) Instructions for checking the signal strength when connected.

  One strategy is to see if there's an existing modem that looks similar to yours
  and modify it.
  """

  @typedoc """
  Information about a service provider

  * `:apn` (required) - e.g., `"access_point_name"`
  * `:usage` (optional) - `:eps_bearer` (LTE) or `:pdp` (UMTS/GPRS)
  """
  @type service_provider_info() :: %{
          required(:apn) => String.t(),
          optional(:usage) => :eps_bearer | :pdp
        }

  @typedoc """
  The `:vintage_net_mobile` option in the configuration map

  Only the `:service_providers` key must be specified. Modems may
  add keys of their own.
  """
  @type mobile_options() :: %{
          required(:service_providers) => service_provider_info(),
          optional(:chatscript_additions) => iodata(),
          optional(any) => any
        }

  @typedoc """
  Radio Access Technology (RAT)

  These define how to connect to the cellular network.
  """
  @type rat() :: :gsm | :td_scdma | :wcdma | :lte | :cdma | :lte_cat_nb1 | :lte_cat_m1

  @impl VintageNet.Technology
  def normalize(%{type: __MODULE__, vintage_net_mobile: mobile} = config) do
    modem = Map.fetch!(mobile, :modem)

    modem.normalize(config)
  end

  @impl VintageNet.Technology
  def to_raw_config(ifname, %{type: __MODULE__, vintage_net_mobile: mobile} = config, opts) do
    modem = Map.fetch!(mobile, :modem)

    %RawConfig{
      ifname: ifname,
      type: __MODULE__,
      source_config: config,
      required_ifnames: [ppp_to_wwan(ifname)]
    }
    |> modem.add_raw_config(config, opts)
    |> add_start_commands(modem)
    |> add_cleanup_command()
  end

  @impl VintageNet.Technology
  def ioctl(_ifname, _command, _args), do: {:error, :unsupported}

  @impl VintageNet.Technology
  def check_system(_), do: {:error, "unimplemented"}

  defp add_start_commands(raw_config, _modem) do
    # The mknod creates `/dev/ppp` if it doesn't exist.
    # The mkdir creates `/var/run/pppd/lock` if it doesn't exist.
    new_up_cmds = [
      {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]},
      {:run_ignore_errors, "mkdir", ["-p", "/var/run/pppd/lock"]} | raw_config.up_cmds
    ]

    %RawConfig{raw_config | up_cmds: new_up_cmds}
  end

  defp add_cleanup_command(raw_config) do
    cmds = [
      {:fun, PropertyTable, :delete_matches,
       [VintageNet, ["interface", raw_config.ifname, "mobile"]]}
      | raw_config.down_cmds
    ]

    %RawConfig{raw_config | down_cmds: cmds}
  end

  defp ppp_to_wwan("ppp" <> index), do: "wwan" <> index
  defp ppp_to_wwan(something_else), do: something_else
end
