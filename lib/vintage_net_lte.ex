defmodule VintageNetLTE do
  @behaviour VintageNet.Technology

  alias VintageNet.Interface.RawConfig
  alias VintageNetLTE.Modems

  @moduledoc """
  Use cellular modems with VintageNet

  Examples:

  ```elixir
      VintageNet.configure(
        "ppp0",
        %{
          type: VintageNetLTE,
          modem: your_modem,
          service_provider: your_service_provider
        }
      )
  ```

  or add this to your `config.exs`:

  ```elixir
  config :vintage_net,
    config: [
      {"ppp0", %{type: VintageNetLTE, modem: your_modem, service_provider: your_service_provider}}
    ]
  ```

  ## Custom Modems

  `VintageNetLTE` allows you add custom modem implementations if the built-in
  implementations don't work for you:

  ```elixir
  config :vintage_net_lte,
    extra_modems: [MyBestLTEEverModem]
  ```

  Modem implementations need to implement the `VintageNetLTE.Modem` behaviour.
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
    service_provider = Map.get(config, :service_provider)
    modem_implementation = Modems.lookup(modem, service_provider)

    %RawConfig{
      ifname: ifname,
      type: __MODULE__,
      source_config: config
    }
    |> modem_implementation.add_raw_config(config, opts)
  end

  @impl true
  def ioctl(_ifname, _command, _args), do: {:error, :unsupported}

  # TODO: implement
  @impl true
  def check_system(_), do: :ok

  @doc """
  Make the chatscript path for the interface
  """
  @spec chatscript_path(binary(), keyword()) :: binary()
  def chatscript_path(ifname, opts) do
    Path.join(Keyword.fetch!(opts, :tmpdir), "chatscript.#{ifname}")
  end
end
