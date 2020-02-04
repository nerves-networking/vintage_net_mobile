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
  def spec(provider_info) do
    %{
      serial_port: "/dev/ttyUSB3",
      serial_speed: 9600,
      chatscript: chatscript(provider_info)
    }
  end

  defp chatscript(provider_info) do
    """
    # Exit execution if module receives any of the following strings:
    ABORT 'BUSY'
    ABORT 'NO CARRIER'
    ABORT 'NO DIALTONE'
    ABORT 'NO DIAL TONE'
    ABORT 'NO ANSWER'
    ABORT 'DELAYED'
    TIMEOUT 10
    REPORT CONNECT

    # Module will send the string AT regardless of the string it receives
    "" AT

    # Instructs the modem to disconnect from the line, terminating any call in progress. All of the functions of the command shall be completed before the modem returns a result code.
    OK ATH

    # Instructs the modem to set all parameters to the factory defaults.
    OK ATZ

    # Result codes are sent to the Data Terminal Equipment (DTE).
    OK ATQ0

    # Define PDP context
    OK AT+CGDCONT=1,"IP","#{provider_info.apn}"

    # ATDT = Attention Dial Tone
    OK ATDT*99***1#

    # Don't send any more strings when it receives the string CONNECT. Module considers the data links as having been set up.
    CONNECT ''

    """
  end
end
