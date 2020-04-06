defmodule VintageNetMobile.ExChat.Request do
  @moduledoc false

  defstruct id: nil,
            request: "",
            success: "OK",
            errors: [
              "ERROR",
              "BUSY",
              "NO CARRIER",
              "NO DIALTONE",
              "NO DIAL TONE",
              "NO ANSWER",
              "DELAYED"
            ],
            timeout: 10_000

  @type t :: %__MODULE__{
          id: any(),
          request: binary(),
          success: binary(),
          errors: [binary()],
          timeout: non_neg_integer()
        }

  @spec new(binary(), any(), keyword()) :: t()
  def new(request, who, opts) do
    %__MODULE__{
      id: who,
      request: request
    }
    |> Map.merge(Map.new(opts))
  end
end
