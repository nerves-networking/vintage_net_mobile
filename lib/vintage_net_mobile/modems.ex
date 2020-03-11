defmodule VintageNetMobile.Modems do
  @moduledoc """
  The list of modem names with provider names that point to a module that
  implements the `VintageNetMobile.Modem` behaviour.

  You can add support for custom modems using the `:extra_modems` key in
  the configuration.

  ```elixir
  config :vintage_net_mobile,
    extra_modems: [
      {"BestLTEEver Modem", MyBestLTEEverModem}
    ]
  ```
  """

  @default_modems [
    VintageNetMobile.Modem.QuectelBG96,
    VintageNetMobile.Modem.QuectelEC25,
    VintageNetMobile.Modem.UbloxTOBYL2
  ]

  @doc """
  Look up the modem module for the given modem name and provider name

  If there is no modem spec for that modem-provider pair this function raise an
  `ArgumentError`
  """
  @spec lookup(String.t(), String.t()) :: module() | nil
  def lookup(modem, service_provider) do
    opts = Application.get_all_env(:vintage_net_mobile)
    default_modems = modems_to_map(@default_modems)
    extra_modems = modems_to_map(Keyword.get(opts, :extra_modems, []))

    modems = Map.merge(default_modems, extra_modems)

    case lookup(modems, modem, service_provider) do
      nil ->
        raise ArgumentError, """
        It looks like you are trying to use a modem-provider pair that is not supported by VintageNetMobile.

        Modem: #{modem}

        Service provider: #{service_provider}

        Ensure you are using a modem-provider pair that VintageNetMobile supports.
        """

      modem_module ->
        modem_module
    end
  end

  defp lookup(modems, modem, providers) do
    # See if there's a provider-specific implementation first and then
    # try a generic one.
    Enum.find_value(providers, fn provider ->
      Map.get(modems, {modem, provider}) || Map.get(modems, {modem, :_})
    end)
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
