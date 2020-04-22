defmodule VintageNetMobile.Modem do
  @moduledoc """
  A behaviour for modem implementations
  """

  alias VintageNet.Interface.RawConfig

  @doc """
  Normalize a modem configuration

  Modem implementations use this to update the `:modem_opts` key to a canonical
  representation. This could be adding default fields, migrating old options,
  or deriving parameters to that they need not be computed again.

  Configuration errors raise exceptions.
  """
  @callback normalize(config :: map()) :: map()

  @doc """
  Update the raw configuration for the modem

  The incoming raw configuration (first parameter) will have an initial generic
  configuration that should be common to most modems. The second parameter is
  the normalized VintageNet configuration and the final options are the ones
  from VintageNet for determining file paths, etc.

  Configuration errors raise exceptions, but it is good practice to catch the
  errors in `normalize/1`.
  """
  @callback add_raw_config(RawConfig.t(), config :: map(), opts :: keyword()) :: RawConfig.t()
end
