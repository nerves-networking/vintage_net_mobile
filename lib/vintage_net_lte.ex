defmodule VintageNetLTE do
  @behaviour VintageNet.Technology

  alias VintageNet.Interface.RawConfig
  alias VintageNetLTE.ServiceProvider.Twilio

  require Logger

  @impl true
  def normalize(config), do: config

  @impl true
  def to_raw_config(ifname, %{type: __MOUDLE__} = config, opts) do
    Logger.error("PPP0!!!!!!!!!!!")
    pppd = Keyword.fetch!(opts, :bin_pppd)
    chat = Keyword.fetch!(opts, :bin_chat)
    tmpdir = Keyword.fetch!(opts, :tmpdir)

    # TODO: make this a config item
    serial_port = "/dev/ttyUSB0"

    # TODO: make this a config item
    # should be allowed to pass in integer
    # we can normalize the integer into a
    # string
    serial_speed = "115200"

    # TODO: make service provider configurable
    chatscript_path = Path.join(tmpdir, "#{Twilio.name()}")

    files = [{chatscript_path, Twilio.chatscript()}]

    # TODO: up command may differ between modems
    # should make this configurable
    up_cmds = [
      {:fun, __MODULE__, :run_usbmodeswitch, []},
      {:fun, __MODULE__, :run_mknod, []}
    ]

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

    %RawConfig{
      ifname: ifname,
      type: __MODULE__,
      source_config: config,
      files: files,
      up_cmds: up_cmds,
      require_interface: false,
      child_specs: child_specs
    }
  end

  @impl true
  def ioctl(_ifname, _command, _args), do: {:error, :unsupported}

  # TODO: implement
  @impl true
  def check_system(_), do: :ok

  def chat_script_path() do
    Path.join(System.tmp_dir!(), "twilio")
  end

  def write_chat_script() do
    :ok = File.write(chat_script_path(), Twilio.chatscript())
  end

  def run_mknod() do
    System.cmd("mknod", ["/dev/ppp", "c", "108", "0"])
    :timer.sleep(1_000)
    :ok
  end

  def run_usbmodeswitch() do
    {_, 0} = System.cmd("usb_modeswitch", ["-v", "12d1", "-p", "14fe", "-J"])
    :timer.sleep(1_000)
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
#        "defaultroute",
        "noauth",
        "persist"
      ]
      |> add_debug_to_opts(debug)

    MuonTrap.Daemon.start_link("pppd", pppd_opts)
  end

  defp add_debug_to_opts(pppd_opts, true), do: pppd_opts ++ ["debug"]
  defp add_debug_to_opts(pppd_opts, false), do: pppd_opts
end
