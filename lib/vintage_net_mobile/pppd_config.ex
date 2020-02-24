defmodule VintageNetMobile.PPPDConfig do
  @moduledoc """
  Module for configuring PPPD
  """

  alias VintageNetMobile.Chatscript
  alias VintageNet.Interface.RawConfig

  @doc """
  Add the PPPD child specs to the `RawConfig.t()`
  """
  @spec add_child_spec(RawConfig.t(), binary(), non_neg_integer(), keyword()) :: RawConfig.t()
  def add_child_spec(raw_config, serial_port, serial_speed, opts) do
    child_specs = raw_config.child_specs
    pppd_bin = Keyword.fetch!(opts, :bin_pppd)
    priv_dir = Application.app_dir(:vintage_net_mobile, "priv")
    pppd_shim_path = Path.join(priv_dir, "pppd_shim.so")
    pppd_args = make_pppd_args(raw_config.ifname, serial_port, serial_speed, opts)

    env = [{"PRIV_DIR", priv_dir}, {"LD_PRELOAD", pppd_shim_path}]

    pppd_spec = {MuonTrap.Daemon, [pppd_bin, pppd_args, [env: env]]}

    %RawConfig{raw_config | child_specs: [pppd_spec | child_specs]}
  end

  defp make_pppd_args(ifname, serial_port, serial_speed, opts) do
    chat_bin = Keyword.fetch!(opts, :bin_chat)
    cs_path = Chatscript.path(ifname, opts)

    serial_speed = Integer.to_string(serial_speed)

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
end
