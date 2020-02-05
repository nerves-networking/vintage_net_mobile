defmodule VintageNetLTE.ATParserTest do
  use ExUnit.Case

  alias VintageNetLTE.ATParser

  test "can parse the at response for signal quality" do
    assert {:csq, {5, 99}} == ATParser.parse_at_response("+CSQ: 5,99")
  end
end
