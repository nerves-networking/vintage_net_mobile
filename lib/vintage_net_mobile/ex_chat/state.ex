# SPDX-FileCopyrightText: 2020 Frank Hunleth
# SPDX-FileCopyrightText: 2022 Matt Ludwigs
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VintageNetMobile.ExChat.State do
  @moduledoc false

  alias VintageNetMobile.ExChat.Request

  defstruct queued_requests: :queue.new(),
            request: nil,
            request_timer: nil,
            responses: [],
            listeners: []

  @type t() :: %__MODULE__{
          queued_requests: :queue.queue(Request.t()),
          request: Request.t() | nil,
          request_timer: reference() | nil,
          responses: [binary()],
          listeners: [{binary(), any()}]
        }
end
