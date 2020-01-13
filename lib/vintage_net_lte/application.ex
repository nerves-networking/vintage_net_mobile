defmodule VintageNetLTE.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {VintageNet.PPPToElixir.Server, "/tmp/doesntmatter"}
    ]

    opts = [stragtegy: :rest_for_one, name: VintageNetLTE.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
