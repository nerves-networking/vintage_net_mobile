defmodule VintageNetLTE do
  @behaviour VintageNet.Technology

  alias VintageNet.Interface.RawConfig
  alias VintageNetLTE.ServiceProvider.Twilio
  alias VintageNetLTE.SignalStrengthMonitor

  @impl true
  def normalize(config), do: config

  @impl true
  def to_raw_config(ifname, %{type: __MODULE__} = config, opts) do
    files = [{chatscript_path(opts), Twilio.chatscript()}]

    # TODO: up command may differ between modems
    # should make this configurable
    up_cmds = [
      {:fun, __MODULE__, :run_usb_modeswitch, []},
      {:fun, __MODULE__, :run_mknod, []}
    ]

    # TODO: figure out a nicer way to specify options for
    # polling the signal strength
    child_specs = [
      {SignalStrengthMonitor, [ifname: ifname, tty: "/dev/ttyUSB2", speed: 115_200]},
      make_pppd_spec(opts)
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

  defp make_pppd_spec(opts) do
    pppd_bin = Keyword.fetch!(opts, :bin_pppd)
    priv_dir = Application.app_dir(:vintage_net_lte, "priv")
    pppd_shim_path = Path.join(priv_dir, "pppd_shim.so")
    pppd_args = make_pppd_args(opts)

    env = [{"PRIV_DIR", priv_dir}, {"LD_PRELOAD", pppd_shim_path}]

    {MuonTrap.Daemon, [pppd_bin, pppd_args, [env: env]]}
  end

  defp make_pppd_args(opts) do
    chat_bin = Keyword.fetch!(opts, :bin_chat)
    cs_path = chatscript_path(opts)
    # TODO: make this a config item
    serial_port = "/dev/ttyUSB0"

    # TODO: make this a config item
    # should be allowed to pass in integer
    # we can normalize the integer into a
    # string
    serial_speed = "115200"

    [
      "connect",
      "#{chat_bin} -v -f #{cs_path}",
      serial_port,
      serial_speed,
      "noipdefault",
      "usepeerdns",
      "persist",
      "noauth",
      "nodetach",
      "debug"
    ]
  end

  defp chatscript_path(opts) do
    opts
    |> Keyword.fetch!(:tmpdir)
    |> Path.join(Twilio.name())
  end

  def run_mknod() do
    _ = System.cmd("mknod", ["/dev/ppp", "c", "108", "0"])
    :timer.sleep(1_000)
    :ok
  end

  def run_usb_modeswitch() do
    _ = System.cmd("usb_modeswitch", ["-v", "12d1", "-p", "14fe", "-J"])
    :timer.sleep(1_000)
    :ok
  end
end
