defmodule VintageNetMobile.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {VintageNetMobile.ToElixir.Server, "/tmp/vintage_net/pppd_comms"}
    ]

    opts = [strategy: :rest_for_one, name: VintageNetMobile.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
