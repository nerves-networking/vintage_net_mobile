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
          service_providers: your_service_providers
        }
      )
  ```

  or add this to your `config.exs`:

  ```elixir
  config :vintage_net,
    config: [
      {"ppp0",
      %{type: VintageNetMobile, modem: your_modem, service_providers: your_service_providers}}
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

  `{"A Provider", apn: "apn.provider.net"}`
  """
  @type service_provider_info :: {String.t(), [apn: String.t()]}

  @typedoc """
  TODO
  """
  @type opt :: {:extra_modems, [module()]} | {:extra_service_providers, [service_provider_info()]}

  @impl true
  def normalize(config), do: config

  @impl true
  def to_raw_config(ifname, %{type: __MODULE__, modem: modem} = config, opts) do
    case modem.validate_config(config) do
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
        Invalid configuration: #{inspect(reason)}

        Please check your modem documentation to see the correct configuration.
        """
    end
  end

  @impl true
  def ioctl(_ifname, _command, _args), do: {:error, :unsupported}

  # TODO: implement
  @impl true
  def check_system(_), do: :ok

  defp add_ready_command(raw_config, modem_implementation) do
    new_up_cmds = [{:fun, modem_implementation, :ready, []} | raw_config.up_cmds]

    %RawConfig{raw_config | up_cmds: new_up_cmds}
  end
end
