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
      modem: your_modem,
      service_providers: your_service_providers
    }
  )
  ```

  The `:modem` key should be set to your modem implementation. Cellular modems
  tend to be very similar. If `vintage_net_mobile` doesn't list your modem, see
  the customizing section. It may just be a copy/paste away.

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
      service_providers: [
        %{apn: "wireless.twilio.com"}
      ]
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
  @type service_provider_info :: %{
          required(:apn) => String.t(),
          optional(:usage) => :eps_bearer | :pdp
        }

  @impl true
  def normalize(config), do: config

  @impl true
  def to_raw_config(ifname, %{type: __MODULE__, modem: modem} = config, opts) do
    service_providers = Map.get(config, :service_providers)

    case modem.validate_service_providers(service_providers) do
      :ok ->
        %RawConfig{
          ifname: ifname,
          type: __MODULE__,
          source_config: config
        }
        |> modem.add_raw_config(config, opts)
        |> add_ready_command(modem)
        |> add_cleanup_command()

      {:error, reason} ->
        raise ArgumentError, """
        Looks like you provided invalid service providers because #{inspect(reason)}.

        Please see your modem's documentation in regards to what it expects from
        the configured service providers
        """
    end
  end

  @impl true
  def ioctl(_ifname, _command, _args), do: {:error, :unsupported}

  # TODO: implement
  @impl true
  def check_system(_), do: :ok

  defp add_ready_command(raw_config, modem) do
    new_up_cmds = [{:fun, modem, :ready, []} | raw_config.up_cmds]

    %RawConfig{raw_config | up_cmds: new_up_cmds}
  end

  defp add_cleanup_command(raw_config) do
    cmds = [
      {:fun, VintageNet.PropertyTable, :clear_prefix,
       [VintageNet, ["interface", raw_config.ifname, "mobile"]]}
      | raw_config.down_cmds
    ]

    %RawConfig{raw_config | down_cmds: cmds}
  end
end
