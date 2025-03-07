# SPDX-FileCopyrightText: 2019 Matt Ludwigs
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Utils do
  @spec default_opts() :: keyword()
  def default_opts() do
    # Use the defaults in mix.exs, but normalize the paths to commands
    Application.get_all_env(:vintage_net)
  end
end

ExUnit.start()
