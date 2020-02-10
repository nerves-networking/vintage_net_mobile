defmodule VintageNetLTE.Modems do
  @moduledoc """
  Module for working with supported modems
  """
  alias VintageNetLTE.Modems.Table
  alias VintageNetLTE.Modem

  @doc """
  The specification for the modem given the modem and provider name

  If there is no modem spec for that modem/provider pair this function will
  return `nil`
  """
  @spec get_modem_spec(String.t(), String.t()) :: Modem.spec() | nil
  def get_modem_spec(modem, provider) do
    case Table.lookup(modem, provider) do
      nil -> nil
      modem -> modem.spec(provider)
    end
  end
end
