# SPDX-FileCopyrightText: 2020 Frank Hunleth
# SPDX-FileCopyrightText: 2020 Matt Ludwigs
# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
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
            ]} == ATParser.parse(~S[+QSPN: "Twilio","Twilio","",0,"310260"])

    assert {:ok, "+QNWINFO: ",
            [
              "FDD LTE",
              "310260",
              "LTE BAND 4",
              2300
            ]} == ATParser.parse(~S[+QNWINFO: "FDD LTE","310260","LTE BAND 4",2300])

    assert {:ok, "+QNWINFO: ",
            [
              "No Service",
              "",
              "",
              0
            ]} == ATParser.parse("+QNWINFO: No Service")

    assert {:ok, "+QLTS: ", ["2020/03/13,13:21:36-16,1"]} ==
             ATParser.parse(~S[+QLTS: "2020/03/13,13:21:36-16,1"])

    assert {:ok, "+QCFG: ",
            [
              "band",
              0x260,
              0x42000000000000381A,
              0
            ]} == ATParser.parse("+QCFG: \"band\",0x260,0x42000000000000381a,0x0")

    assert {:ok, "+QIND: ", ["act", "LTE"]} == ATParser.parse(~S[+QIND: "act","LTE"])

    assert {:ok, "+QIND: ", ["csq", 21, 99]} == ATParser.parse(~S[+QIND: "csq",21,99])

    assert {:ok, "+QCCID: ", ["8901260852290847433F"]} ==
             ATParser.parse("+QCCID: 8901260852290847433F")
  end

  test "errors on corrupt notifications" do
    # Missing colon
    assert {:error, "Parse error {:illegal, #{inspect(~c"+CSQ ")}} for \"+CSQ 5,99\"}"} ==
             ATParser.parse("+CSQ 5,99")

    # Missing header
    assert {:error, "Expecting string to start with '+XYZ: ', but got \"5,99\""} ==
             ATParser.parse("5,99")

    # Empty string
    assert {:error, "Expecting string to start with '+XYZ: ', but got \"\""} == ATParser.parse("")

    # Bad integer value
    assert {:error, "Parse error {:illegal, #{inspect(~c"A")}} for \"+CSQ: 5A,99\"}"} ==
             ATParser.parse("+CSQ: 5A,99")

    # Bad hex value
    assert {:error, "Parse error {:illegal, #{inspect(~c"z")}} for \"+CSQ: 0x12aAz,99\"}"} ==
             ATParser.parse("+CSQ: 0x12aAz,99")

    # Missing close quote
    assert {:error,
            "Parse error {:illegal, #{inspect(~c"\"Missing quote")}} for \"+CSQ: \\\"Missing quote\"}"} ==
             ATParser.parse("+CSQ: \"Missing quote")
  end
end
