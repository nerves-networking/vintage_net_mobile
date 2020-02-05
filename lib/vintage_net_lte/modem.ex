defmodule VintageNetLTE.Modem do
  @moduledoc """
  A behaviour for providing a specification for a modem to use with the
  VintageNetLTE runtime.
  """

  @typedoc """
  The modem spec requires these fields:

  * `:serial_port` - this is the tty the modem is connected to
  * `:serial_speed` - this is baud rate for the serial connection
  * `:chatscript` - the file contents of the chatscript
  * `:command_port` - the tty port for sending AT commands
  """
  @type spec :: %{
          serial_port: String.t(),
          serial_speed: non_neg_integer(),
          chatscript: String.t(),
          command_port: String.t()
        }

  @doc """
  Return the modem spec
  """
  @callback spec(VintageNetLTE.provider_info()) :: spec()
end
