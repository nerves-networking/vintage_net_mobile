defmodule VintageNetLTE.ATParser do
  @moduledoc false

  @type report_type :: atom()
  @type report_data :: term()

  @type report :: {report_type(), term()} | :ok_report

  @doc """
  Parse the raw AT report into an Elixir data structure
  """
  @spec parse_report(binary()) :: report()
  def parse_report(resp) do
    case resp do
      "OK" -> :ok_report
      "+CSQ" <> _rest -> decode_csq_resp(resp)
      other -> {:unsupported, other}
    end
  end

  defp decode_csq_resp(resp) do
    [_csq_label, values] = String.split(resp, ":")
    [rssi_str, bit_error_rate_str] = String.split(values, ~r/\s|,/, trim: true)
    rssi = String.to_integer(rssi_str)
    bit_error_rate = String.to_integer(bit_error_rate_str)

    {:csq_report, {rssi, bit_error_rate}}
  end
end
