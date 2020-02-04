defmodule VintageNetLTE.Modems.MockModem do
  @behaviour VintageNetLTE.Modem

  @impl true
  def spec(_provider_info) do
    %{serial_port: "/dev/null", serial_speed: 115_200, chatscript: ""}
  end
end
