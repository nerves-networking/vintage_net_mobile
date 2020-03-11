defmodule VintageNetMobile do
  @behaviour VintageNet.Technology

  alias VintageNet.Interface.RawConfig

  @moduledoc """
  Use cellular modems with VintageNet

  Examples:

  ```elixir
      VintageNet.configure(
        "ppp0",
        %{
          type: VintageNetMobile,
          modem: your_modem,
          service_provider: your_service_provider
        }
      )
  ```

  or add this to your `config.exs`:

  ```elixir
  config :vintage_net,
    config: [
      {"ppp0", %{type: VintageNetMobile, modem: your_modem, service_provider: your_service_provider}}
    ]
  ```

  ## Custom Modems

  `VintageNetMobile` allows you add custom modem implementations if the built-in
  implementations don't work for you:

  ```elixir
  config :vintage_net_mobile,
    extra_modems: [MyBestLTEEverModem]
  ```

  Modem implementations need to implement the `VintageNetMobile.Modem` behaviour.
  """

  @typedoc """
  Information about a service provider

  For example:

  `%{apn: "apn.provider.net"}`
  """
  @type service_provider_info :: %{apn: String.t()}

  @typedoc """
  VintageNetMobile options

  * `:extra_modems` - list of extra modems that can tie into the `VintageNet` runtime
     via `VintageNetMobile`
  """
  @type opt :: {:extra_modems, [module()]}

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
end
