defmodule VintageNetMobile.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    env = Application.get_all_env(:vintage_net_mobile)

    children = [
      {VintageNetMobile.ToElixir.Server, "/tmp/vintage_net/pppd_comms"},
      {VintageNetMobile.Modems, env}
    ]

    opts = [strategy: :rest_for_one, name: VintageNetMobile.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
