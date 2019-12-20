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

    {_modem, modem_opts} = config.modem

    serial_port = Keyword.fetch!(modem_opts, :serial_port)
    serial_speed = Keyword.fetch!(modem_opts, :speed)

    chatscript_path = Path.join(tmpdir, "ppp.#{ifname}")

    files = [{chatscript_path, config.chatscript.contents()}]

    child_specs = [
      {VintageNetLTE.PPPD,
       [
         chatscript: chatscript_path,
         pppd: pppd,
         chat: chat,
         ifname: ifname,
         speed: serial_speed,
         serial: serial_port
       ]}
    ]

    :ok = File.write(chatscript_path, twillio_chatscript())

    %RawConfig{
      ifname: ifname,
      type: __MODULE__,
      source_config: config,
      files: files,
      child_specs: child_specs
    }
  end

  @impl true
  def ioctl(_ifname, _command, _args), do: {:error, :unsupported}

  @impl true
  def check_system(_), do: :ok
end
