defmodule VintageNetMobile.ATParser do
  @moduledoc false

  @type args() :: integer() | binary()

  @doc """
  Parse an AT notification
  """
  @spec parse(binary()) ::
          {:ok, header :: binary(), [args()]} | {:error, any()}
  def parse("+QCCID: " <> id) do
    {:ok, "+QCCID: ", [id]}
  end

  def parse("+QNWINFO: No Service") do
    {:ok, "+QNWINFO: ", ["No Service", "", "", 0]}
  end

  def parse(line) do
    line
    |> to_charlist()
    |> :at_lexer.string()
    |> to_return_value(line)
  end

  defp to_return_value({:ok, [{:header, header} | args], _line_number}, _line) do
    {:ok, header, args}
  end

  defp to_return_value({:ok, _other, _line_number}, line) do
    {:error, "Expecting string to start with '+XYZ: ', but got #{inspect(line)}"}
  end

  defp to_return_value({:error, {1, :at_lexer, reason}, 1}, line) do
    {:error, "Parse error #{inspect(reason)} for #{inspect(line)}}"}
  end
end
