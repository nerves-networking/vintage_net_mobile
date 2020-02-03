defmodule VintageNetLTE.Modems.QuectelBG96Test do
  use ExUnit.Case

  alias VintageNetLTE.Modems.QuectelBG96

  test "returns correct spec" do
    assert %{serial_port: "/dev/ttyUSB3", serial_speed: 9600} = QuectelBG96.spec()
  end
end
