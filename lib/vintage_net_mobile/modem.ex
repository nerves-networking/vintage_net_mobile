defmodule VintageNetMobile.Modem do
  @moduledoc """
  A behaviour for providing a specification for a modem to use with the
  VintageNetMobile runtime.
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
  All the modem to validate the configuration provided
  """
  @callback validate_config(map()) :: :ok | {:error, reason :: any()}
end
