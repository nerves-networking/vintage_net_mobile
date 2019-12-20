defmodule VintageNetLTE do
  @behaviour VintageNet.Technology

  alias VintageNet.Interface.RawConfig

  @impl true
  def normalize(config), do: config

  @impl true
  def to_raw_config(ifname, %{type: __MOUDLE__} = config, opts) do
    pppd = Keyword.fetch!(opts, :bin_pppd)
    chat = Keyword.fetch!(opts, :bin_chat)
    tmpdir = Keyword.fetch!(opts, :tmpdir)

    chatscript_path = Path.join(tmpdir, "ppp.#{ifname}")

    files = [{chatscript_path, twillio_chatscript()}]

    child_specs = [
      {VintageNetLTE.PPPD, [chatscript: chatscript_path, pppd: pppd, chat: chat, ifname: ifname]}
    ]

    :ok = File.write(chatscript_path, twillio_chatscript())

    %RawConfig{
      ifname: ifname,
      type: __MODULE__,
      source_config: config,
      files: files
      #    child_specs: child_specs
    }
  end

  @impl true
  def ioctl(_ifname, _command, _args), do: {:error, :unsupported}

  @impl true
  def check_system(_), do: :ok

  defp twillio_chatscript() do
    """
    # See http://consumer.huawei.com/solutions/m2m-solutions/en/products/support/application-guides/detail/mu509-65-en.htm?id=82047

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
    OK AT+CGDCONT=1,"IP","wireless.twilio.com"

    # ATDT = Attention Dial Tone
    OK ATDT*99***1#

    # Don't send any more strings when it receives the string CONNECT. Module considers the data links as having been set up.
    CONNECT ''

    """
  end
end
