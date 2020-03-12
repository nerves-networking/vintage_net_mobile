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

    assert expected_chatscript == Chatscript.default([%{apn: "fake.apn.com"}])
  end
end
