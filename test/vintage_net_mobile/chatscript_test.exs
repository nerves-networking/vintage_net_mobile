# SPDX-FileCopyrightText: 2020 Frank Hunleth
# SPDX-FileCopyrightText: 2020 Matt Ludwigs
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VintageNetMobile.ChatscriptTest do
  use ExUnit.Case

  alias VintageNetMobile.Chatscript

  test "outputs the right chatscript path" do
    assert "/tmp/vintage_net/chatscript.ppp0" == Chatscript.path("ppp0", Utils.default_opts())
  end

  test "outputs the basic default chatscript" do
    expected_chatscript = """
    ABORT 'BUSY'
    ABORT 'NO CARRIER'
    ABORT 'NO DIALTONE'
    ABORT 'NO DIAL TONE'
    ABORT 'NO ANSWER'
    ABORT 'DELAYED'
    TIMEOUT 10
    REPORT CONNECT
    "" +++
    "" AT
    OK ATH
    OK ATZ
    OK ATQ0
    OK AT+CGDCONT=1,"IP","fake.apn.com"
    OK ATDT*99***1#
    CONNECT ''
    """

    modem_config = %{
      service_providers: [%{apn: "fake.apn.com"}]
    }

    assert expected_chatscript == Chatscript.default(modem_config)
  end

  test "chatscript additions get inserted" do
    expected_chatscript = """
    ABORT 'BUSY'
    ABORT 'NO CARRIER'
    ABORT 'NO DIALTONE'
    ABORT 'NO DIAL TONE'
    ABORT 'NO ANSWER'
    ABORT 'DELAYED'
    TIMEOUT 10
    REPORT CONNECT
    "" +++
    "" AT
    OK ATH
    OK ATZ
    OK ATQ0
    OK AT+CGDCONT=1,"IP","fake.apn.com"
    OK AT+KSIMSEL=2
    OK AT+KSIMSEL=3
    OK ATDT*99***1#
    CONNECT ''
    """

    modem_config = %{
      service_providers: [%{apn: "fake.apn.com"}],
      chatscript_additions: """
      OK AT+KSIMSEL=2
      OK AT+KSIMSEL=3
      """
    }

    assert expected_chatscript == Chatscript.default(modem_config)

    # Check iodata
    modem_config = %{
      service_providers: [%{apn: "fake.apn.com"}],
      chatscript_additions: ["OK", " ", "AT+KSIMSEL=2", "\n", "OK", " ", "AT+KSIMSEL=3"]
    }

    assert expected_chatscript == Chatscript.default(modem_config)

    # Check that modem chatscript additions come first
    modem_config = %{
      service_providers: [%{apn: "fake.apn.com"}],
      chatscript_additions: "OK AT+KSIMSEL=3"
    }

    assert expected_chatscript == Chatscript.default(modem_config, "OK AT+KSIMSEL=2\n")
  end
end
