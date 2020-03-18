defmodule VintageNetMobile.ATParserTest do
  use ExUnit.Case

  alias VintageNetMobile.ATParser

  test "parses notifications" do
    assert {:ok, "+CSQ: ", [5, 99]} = ATParser.parse("+CSQ: 5,99")

    assert {:ok, "+QSPN: ",
            [
              "Twilio",
              "Twilio",
              "",
              0,
              "310260"
            ]} = ATParser.parse("+QSPN: \"Twilio\",\"Twilio\",\"\",0,\"310260\"")

    assert {:ok, "+QNWINFO: ",
            [
              "FDD LTE",
              "310260",
              "LTE BAND 4",
              2300
            ]} = ATParser.parse("+QNWINFO: \"FDD LTE\",\"310260\",\"LTE BAND 4\",2300")

    assert {:ok, "+QLTS: ", ["2020/03/13,13:21:36-16,1"]} =
             ATParser.parse("+QLTS: \"2020/03/13,13:21:36-16,1\"")

    assert {:ok, "+QCFG: ",
            [
              "band",
              0x260,
              0x42000000000000381A,
              0
            ]} = ATParser.parse("+QCFG: \"band\",0x260,0x42000000000000381a,0x0")

    assert {:ok, "+QIND: ", ["act", "LTE"]} = ATParser.parse("+QIND: \"act\",\"LTE\"")

    assert {:ok, "+QIND: ", ["csq", 21, 99]} = ATParser.parse("+QIND: \"csq\",21,99")

    assert {:ok, "+QCCID: ", ["8901260852290847433F"]} =
             ATParser.parse("+QCCID: 8901260852290847433F")
  end

  test "errors on corrupt notifications" do
    # Missing colon
    assert {:error, {:illegal, '+CSQ '}} = ATParser.parse("+CSQ 5,99")

    # Missing header
    assert {:error, :missing_at_type} = ATParser.parse("5,99")

    # Empty string
    assert {:error, :missing_at_type} = ATParser.parse("")

    # Bad integer value
    assert {:error, {:illegal, 'A'}} = ATParser.parse("+CSQ: 5A,99")

    # Bad hex value
    assert {:error, {:illegal, 'z'}} = ATParser.parse("+CSQ: 0x12aAz,99")

    # Missing close quote
    assert {:error, {:illegal, '"Missing quote'}} = ATParser.parse("+CSQ: \"Missing quote")
  end
end
