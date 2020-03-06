defmodule VintageNetMobile.ModemsTest do
  use ExUnit.Case

  alias VintageNetMobile.Modems

  test "Get modem specs for Quectel BG96 with service providers" do
    assert VintageNetMobile.Modems.QuectelBG96 ==
             Modems.lookup("Quectel BG96", [%{apn: "wireless.twilio.com"}])
  end

  test "raises when passed an invalid modem-provider pair" do
    assert_raise ArgumentError, fn ->
      Modems.lookup("NotAModem", [])
    end
  end
end
