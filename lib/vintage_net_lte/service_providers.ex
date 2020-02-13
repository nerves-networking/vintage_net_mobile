defmodule VintageNetLTE.ServiceProviders do
  @moduledoc """
  Module for working with service provider specific information in Elixir.

  You can add more service providers via the `:extra_service_providers` key in
  the configuration.

  ```elixir
  config :vintage_net_lte,
    extra_service_providers: [
      {"Ultimate 2G", apn: "ultimate.2g.net"}
    ]
  ```
  """

  @default_service_providers [{"Twilio", apn: "wireless.twilio.com"}]

  @doc """
  Return the APN for the specified service provider
  """
  def apn!(service_provider) do
    {_name, info} = find_service_provider!(service_provider)

    info[:apn]
  end

  defp find_service_provider!(name) do
    find_service_provider(name) ||
      raise ArgumentError, error_message(name)
  end

  defp find_service_provider(name) do
    List.keyfind(@default_service_providers, name, 0) ||
      List.keyfind(extra_service_providers(), name, 0)
  end

  defp error_message(provider_name) do
    [
      """
      The provider: "#{provider_name}" is not supported by VintageNetLTE. Please check your
      configuration to ensure that the provider is one of the below providers:

      """,
      format_service_providers_list(@default_service_providers),
      format_service_providers_list(extra_service_providers())
    ]
    |> IO.iodata_to_binary()
  end

  defp format_service_providers_list(provider_list) do
    for {name, _info} <- provider_list do
      ["  * ", name, "\n"]
    end
  end

  defp extra_service_providers() do
    Application.get_env(:vintage_net_lte, :extra_service_providers, [])
  end
end
