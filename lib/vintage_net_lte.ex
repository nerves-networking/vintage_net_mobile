defmodule VintageNetLTE do
  @behaviour VintageNet.Technology

  alias VintageNet.Interface.RawConfig
  alias VintageNetLTE.ServiceProvider.Twilio

  @impl true
  def normalize(config), do: config

  @impl true
  def to_raw_config(ifname, %{type: __MODULE__, modem: modem} = config, opts) do
    files = [{chatscript_path(opts), Twilio.chatscript()}]

    # TODO: up command may differ between modems
    # should make this configurable
    up_cmds = [
      {:fun, __MODULE__, :run_mknod, []}
    ]

    child_specs = [make_pppd_spec(modem, opts)]

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

  defp make_pppd_spec(modem, opts) do
    pppd_bin = Keyword.fetch!(opts, :bin_pppd)
    priv_dir = Application.app_dir(:vintage_net_lte, "priv")
    pppd_shim_path = Path.join(priv_dir, "pppd_shim.so")
    pppd_args = make_pppd_args(modem, opts)

    env = [{"PRIV_DIR", priv_dir}, {"LD_PRELOAD", pppd_shim_path}]

    {MuonTrap.Daemon, [pppd_bin, pppd_args, [env: env]]}
  end

  defp make_pppd_args(modem, opts) do
    chat_bin = Keyword.fetch!(opts, :bin_chat)
    cs_path = chatscript_path(opts)
    modem_spec = modem.spec()

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
end
