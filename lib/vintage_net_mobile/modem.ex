defmodule VintageNetMobile.Modem do
  @moduledoc """
  A behaviour for modem implementations
  """

  alias VintageNet.Interface.RawConfig

  @doc """
  Update the raw configuration for the modem
  """
  @callback add_raw_config(RawConfig.t(), map(), keyword()) :: RawConfig.t()

  @doc """
  Check to make sure the modem is ready to be used
  """
  @callback ready() :: :ok | {:error, :missing_modem}

  @doc """
  Validate the service providers for the modem
  """
  @callback validate_service_providers([VintageNetMobile.service_provider_info()]) ::
              :ok | {:error, reason :: any()}
end
