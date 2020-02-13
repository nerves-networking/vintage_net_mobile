defmodule VintageNetLTE.ModemsTest do
  use ExUnit.Case

  alias VintageNetLTE.Modems

  test "Get modem specs for Quectel BG96 with Twilio" do
    assert VintageNetLTE.Modems.QuectelBG96 == Modems.lookup("Quectel BG96", "Twilio")
  end

  test "raises when passed an invalid modem-provider pair" do
    assert_raise ArgumentError, fn ->
      Modems.lookup("NotAModem", "NotAProvider")
    end
  end
end
