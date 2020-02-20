defmodule VintageNetLTE.Modems do
  @moduledoc """
  The list of modem names with provider names that point to a module that
  implements the `VintageNetLTE.Modem` behaviour.

  You can add support for custom modems using the `:extra_modems` key in
  the configuration.

  ```elixir
  config :vintage_net_lte,
    extra_modems: [
      {"BestLTEEver Modem", MyBestLTEEverModem}
    ]
  ```
  """

  use Agent

  @default_modems [VintageNetLTE.Modems.QuectelBG96, VintageNetLTE.Modems.QuectelEC25AF]

  @spec start_link([VintageNetLTE.opt()]) :: Agent.on_start()
  def start_link(opts) do
    Agent.start_link(fn -> table(opts) end, name: __MODULE__)
  end

  @doc """
  Look up the modem module for the given modem name and provider name

  If there is no modem spec for that modem-provider pair this function raise an
  `ArgumentError`
  """
  @spec lookup(String.t(), String.t()) :: module() | nil
  def lookup(modem, service_provider) do
    case Agent.get(__MODULE__, &lookup(&1, modem, service_provider)) do
      nil ->
        raise ArgumentError, """
        It looks like you are trying to use a modem-provider pair that is not supported by VintageNetLTE.

        Modem: #{modem}

        Service provider: #{service_provider}

        Ensure you are using a modem-provider pair that VintageNetLTE supports.
        """

      modem_module ->
        modem_module
    end
  end

  defp table(opts) do
    default_modems = modems_to_map(@default_modems)
    extra_modems = modems_to_map(Keyword.get(opts, :extra_modems, []))

    Map.merge(default_modems, extra_modems)
  end

  defp lookup(table, modem, provider) do
    # See if there's a provider-specific implementation first and then
    # try a generic one.
    Map.get(table, {modem, provider}) || Map.get(table, {modem, :_})
  end

  defp modems_to_map(modems) do
    modems
    |> Enum.flat_map(&add_entries/1)
    |> Map.new()
  end

  defp add_entries(module) do
    for spec <- module.specs() do
      {spec, module}
    end
  end
end
