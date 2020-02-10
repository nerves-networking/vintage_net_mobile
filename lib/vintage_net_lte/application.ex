defmodule VintageNetLTE.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {VintageNetLTE.ToElixir.Server, "/tmp/vintage_net/pppd_comms"},
      {VintageNetLTE.Modems.Table,
       extra_modems: Application.get_env(:vintage_net_lte, :extra_modems, [])}
    ]

    opts = [strategy: :rest_for_one, name: VintageNetLTE.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
