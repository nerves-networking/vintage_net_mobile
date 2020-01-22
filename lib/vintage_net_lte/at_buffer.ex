defmodule VintageNetLTE.ATBuffer do
  @moduledoc false

  alias VintageNetLTE.ATParser

  @doc """
  Handle a new AT report and add it to the buffer

  If the report is as `:ok_report` this will return that the AT communication
  is complete and the consumer can process information further.

  If the report is not complete, it will let the consumer know to continue
  waiting for more information from the modem.
  """
  @spec handle_report(list(), binary) :: {:continue, list()} | {:complete, list()}
  def handle_report(at_buffer, report) do
    case ATParser.parse_report(report) do
      :ok_report ->
        {:complete, Enum.reverse(at_buffer)}

      parsed_report ->
        {:continue, [parsed_report | at_buffer]}
    end
  end

  @doc """
  Filter the buffer list to only contain reports that
  we are interested in
  """
  @spec filter_reports(list(), ATParser.report_type()) :: list()
  def filter_reports(report_buffer, report_type) do
    Enum.filter(report_buffer, fn
      {^report_type, _report_data} -> true
      _ -> false
    end)
  end
end
