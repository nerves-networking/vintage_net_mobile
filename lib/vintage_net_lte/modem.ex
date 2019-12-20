defmodule VintageNetLTE.Modem do
  @type cmd :: {binary(), [binary()]}

  @callback before_up_cmds() :: [cmd()]

  @callback modules() :: [String.t()]
end
