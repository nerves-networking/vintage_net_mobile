defmodule VintageNetLTE.Modems.TableTest do
  use ExUnit.Case

  alias VintageNetLTE.Modems.{Table, QuectelBG96}

  test "looks up modem module with modem name and provider name" do
    assert QuectelBG96 == Table.lookup("Quectel BG96", "Twilio")
  end
end
