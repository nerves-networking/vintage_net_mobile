defmodule VintageNetLTE.ATParserTest do
  use ExUnit.Case

  alias VintageNetLTE.ATParser

  test "parses CSQ report" do
    assert {:csq_report, {12, 3}} == ATParser.parse_report("+CSQ: 12,3")
    assert {:csq_report, {15, 1}} == ATParser.parse_report("+CSQ:15,1")
  end

  test "parses OK report" do
    assert :ok_report == ATParser.parse_report("OK")
  end

  test "handles unsupported report" do
    assert {:unsupported, "^HCSQ:\"WCDMA\",33,19,37"} ==
             ATParser.parse_report("^HCSQ:\"WCDMA\",33,19,37")
  end
end
