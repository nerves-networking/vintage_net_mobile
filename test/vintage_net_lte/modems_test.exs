defmodule VintageNetLTE.ModemsTest do
  use ExUnit.Case

  alias VintageNetLTE.Modems

  alias VintageNetLTE.Modems.QuectelBG96

  test "Get module specs for Quectel BG96 with Twilio" do
    expected_spec = QuectelBG96.spec("Twilio")

    assert expected_spec == Modems.get_modem_spec("Quectel BG96", "Twilio")
  end
end
