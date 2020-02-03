defmodule VintageNetLTE.Modems.MockModem do
  @behaviour VintageNetLTE.Modem

  def spec() do
    %{serial_port: "/dev/null", serial_speed: 115_200}
  end
end
