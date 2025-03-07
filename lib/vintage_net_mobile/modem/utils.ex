# SPDX-FileCopyrightText: 2020 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VintageNetMobile.Modem.Utils do
  @moduledoc false

  # These are general utility functions for modem implementations

  @doc """
  Check that the configuration has a service provider and that the service provider has the required fields
  """
  @spec require_a_service_provider(config :: map(), [atom()]) :: map()
  def require_a_service_provider(
        %{type: VintageNetMobile, vintage_net_mobile: mobile} = config,
        required_fields \\ [:apn]
      ) do
    case Map.get(mobile, :service_providers, []) do
      [] ->
        service_provider =
          for field <- required_fields, into: %{} do
            {field, to_string(field)}
          end

        new_config = %{
          config
          | vintage_net_mobile: Map.put(mobile, :service_providers, [service_provider])
        }

        raise ArgumentError,
              """
              At least one service provider is required for #{inspect(mobile.modem)}.

              For example:

              #{inspect(new_config)}
              """

      [service_provider | _rest] ->
        missing =
          Enum.find(required_fields, fn field -> not Map.has_key?(service_provider, field) end)

        if missing do
          raise ArgumentError,
                """
                The service provider '#{inspect(service_provider)}' is missing the `inspect(missing)' field.
                """
        end

        config
    end
  end
end
