defmodule VintageNetLTE do
  @behaviour VintageNet.Technology

  #  alias VintageNet.Interface.RawConfig

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

    # :ok = File.write(chatscript_path, twilio_chatscript())

    #    %RawConfig{
    #      ifname: ifname,
    #      type: __MODULE__,
    #      source_config: config,
    #      files: files,
    #      child_specs: child_specs
    #    }
  end

  @impl true
  def ioctl(_ifname, _command, _args), do: {:error, :unsupported}

  @impl true
  def check_system(_), do: :ok

  def chat_script_path() do
    Path.join(System.tmp_dir!(), "twilio")
  end

  def write_chat_script() do
    :ok = File.write(chat_script_path(), VintageNetLTE.ChatScript.Twilio.contents())
  end

  def run_mknod() do
    System.cmd("mknod", ["/dev/ppp", "c", "108", "0"])
    :ok
  end

  def run_usbmodeswitch() do
    {_, 0} = System.cmd("usb_modeswitch", ["-v", "12d1", "-p", "14fe", "-J"])
    :ok
  end

  def setup() do
    :ok = write_chat_script()
    :ok = run_mknod()
    :ok = run_usbmodeswitch()
  end

  def run_pppd(serial_port, opts \\ []) do
    speed = Keyword.get(opts, :speed, "115200")
    debug = Keyword.get(opts, :debug, false)

    pppd_opts =
      [
        "connect",
        "chat -v -f #{chat_script_path()}",
        serial_port,
        speed,
        "noipdefault",
        "usepeerdns",
        "defaultroute",
        "noauth",
        "persist"
      ]
      |> add_debug_to_opts(debug)

    MuonTrap.Daemon.start_link("pppd", pppd_opts)
  end

  defp add_debug_to_opts(pppd_opts, true), do: pppd_opts ++ ["debug"]
  defp add_debug_to_opts(pppd_opts, false), do: pppd_opts
end
