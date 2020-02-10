defmodule VintageNetLTE do
  @behaviour VintageNet.Technology

  alias VintageNet.Interface.RawConfig
  alias VintageNetLTE.{ATRunner, SignalMonitor, Modems}

  @impl true
  def normalize(config), do: config

  @impl true
  def to_raw_config(ifname, %{type: __MODULE__, modem: modem, provider: provider} = config, opts) do
    modem_spec = Modems.get_modem_spec(modem, provider)
    files = [{chatscript_path(ifname, opts), modem_spec.chatscript}]

    up_cmds = [
      {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]}
    ]

    child_specs = [
      make_pppd_spec(ifname, modem_spec, opts),
      {ATRunner, [tty: modem_spec.command_port, speed: modem_spec.serial_speed]},
      {SignalMonitor, [ifname: ifname, tty: modem_spec.command_port()]}
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

  defp make_pppd_spec(ifname, modem_spec, opts) do
    pppd_bin = Keyword.fetch!(opts, :bin_pppd)
    priv_dir = Application.app_dir(:vintage_net_lte, "priv")
    pppd_shim_path = Path.join(priv_dir, "pppd_shim.so")
    pppd_args = make_pppd_args(ifname, modem_spec, opts)

    env = [{"PRIV_DIR", priv_dir}, {"LD_PRELOAD", pppd_shim_path}]

    {MuonTrap.Daemon, [pppd_bin, pppd_args, [env: env]]}
  end

  defp make_pppd_args(ifname, modem_spec, opts) do
    chat_bin = Keyword.fetch!(opts, :bin_chat)
    cs_path = chatscript_path(ifname, opts)

    serial_speed = Integer.to_string(modem_spec.serial_speed)

    [
      "connect",
      "#{chat_bin} -v -f #{cs_path}",
      modem_spec.serial_port,
      serial_speed,
      "noipdefault",
      "usepeerdns",
      "persist",
      "noauth",
      "nodetach",
      "debug"
    ]
  end

  defp chatscript_path(ifname, opts) do
    Path.join(Keyword.fetch!(opts, :tmpdir), "chatscript.#{ifname}")
  end
end
