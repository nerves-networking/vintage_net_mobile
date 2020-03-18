defmodule VintageNetMobile.ATParser do
  @moduledoc false

  @type args :: integer() | binary()

  @doc """
  Parse an AT notification
  """
  @spec parse(binary()) ::
          {:ok, header :: binary(), [args()]} | {:error, any()}
  def parse("+QCCID: " <> id) do
    {:ok, "+QCCID: ", [id]}
  end

  def parse(line) do
    line
    |> to_charlist()
    |> :at_lexer.string()
    |> to_return_value()
  end

  defp to_return_value({:ok, [{:header, header} | args], _line_number}) do
    {:ok, header, args}
  end

  defp to_return_value({:ok, _other, _line_number}) do
    {:error, :missing_at_type}
  end

  defp to_return_value({:error, {1, :at_lexer, reason}, 1}) do
    {:error, reason}
  end
end
