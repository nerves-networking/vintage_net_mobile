defmodule VintageNetMobile.Modem do
  @moduledoc """
  A behaviour for providing a specification for a modem to use with the
  VintageNetMobile runtime.
  """

  alias VintageNet.Interface.RawConfig

  @typedoc """
  A specification for what modem/providers tuples the implementation handles
  """
  @type spec :: {String.t(), String.t() | :_}

  @doc """
  Return the list of modem/providers tuples handled by this module
  """
  @callback specs() :: [spec()]

  @doc """
  Update the raw configuration for the modem
  """
  @callback add_raw_config(RawConfig.t(), map(), keyword()) :: RawConfig.t()

  @doc """
  Check to make sure the modem is ready to be used
  """
  @callback ready() :: :ok | {:error, :missing_modem}
end
