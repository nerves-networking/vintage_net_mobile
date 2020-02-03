defmodule VintageNetLTE.Modems.QuectelBG96 do
  @moduledoc """
  To force LTE only:

  ```
  at+qcfg="nwscanmode",3,1
  ```

  To read which Radio Access Technology (RAT) is currently set:

  ```
  at+qcfg="nwscanmode"
  ```

  To disable Cat NB1 (should do this if in US):

  ```
  at+qcfg="iotopmode",0,1
  ```

  To enable Cat NB1:

  ```
  at+qcfg="iotopmode",1,1
  ```

  To enable trying both Cat NB1 and Cat M1:

  ```
  at+qcfg="iotopmode",2,1
  ```
  """

  @behaviour VintageNetLTE.Modem

  @impl true
  def spec() do
    %{
      serial_port: "/dev/ttyUSB3",
      serial_speed: 9600
    }
  end
end
