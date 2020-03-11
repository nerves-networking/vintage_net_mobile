defmodule VintageNetMobile.ATParser do
  @moduledoc false

  @doc """
  Parse the at response

  This returns a two tuple that will contain the `response_type()` as the first
  element and the data for that response in the second response

  Current this only supports parsing the CSQ AT response
  """
  @spec parse_at_response(binary()) ::
          {:csq, {rssi :: non_neg_integer(), bit_error_rate :: non_neg_integer()}}
  def parse_at_response("+CSQ: " <> data) do
    [rssi, error_rate] = String.split(data, ",")
    rssi_int = String.to_integer(rssi)
    error_rate_int = String.to_integer(error_rate)

    {:csq, {rssi_int, error_rate_int}}
  end
end
