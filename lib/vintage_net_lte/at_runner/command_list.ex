defmodule VintageNetLTE.ATRunner.CommandList do
  @moduledoc """
  Functions for working with commands to send to a modem

  This data structure provides queueing of commands while a command is
  currently in process.
  """

  defmodule Command do
    @moduledoc """
    A command that is to be sent and handled in the `VintageNetLTE.ATRunner`
    """

    @type t :: %__MODULE__{
            command: binary(),
            stop_response: binary(),
            waiter: GenServer.from(),
            timeout: non_neg_integer()
          }

    defstruct command: nil, stop_response: nil, waiter: nil, timeout: nil

    @doc """
    Should the command be considered done
    """
    @spec stop_response?(t(), binary()) :: boolean()
    def stop_response?(command, response) do
      command.stop_response == response
    end
  end

  @type t :: %__MODULE__{
          queue: :queue.queue(Command.t()),
          current_command: Command.t() | nil
        }

  defstruct current_command: nil,
            queue: :queue.new()

  @doc """
  Put a new `Command.t()` into the command list

  If the command list already has a command, it will queue the new
  command which that new command can be accessed via `next_command/1`
  """
  @spec put(t(), Command.t()) :: t() | {:queued, t()}
  def put(command_list, command) do
    if command_list.current_command == nil do
      %{command_list | current_command: command}
    else
      new_queue = :queue.in(command, command_list.queue)
      {:queued, %{command_list | queue: new_queue, current_command: command}}
    end
  end

  @doc """
  Handle a response from the modem

  If it is determined that the current command has received the correct
  response it will return `{:complete, command, new_command_list}`

  If it is not able to determined the current command can be completed then
  this function will return `:continue` to let the caller know to keep waiting
  """
  @spec handle_response(t(), binary()) :: {:complete, Command.t(), t()} | :continue
  def handle_response(%__MODULE__{current_command: nil}, _), do: :continue

  def handle_response(command_list, response) do
    if Command.stop_response?(command_list.current_command, response) do
      {:complete, command_list.current_command, %{command_list | current_command: nil}}
    else
      :continue
    end
  end

  @doc """
  Get the next command from the queued ones

  If there are more commands available to run this will return
  `{Command.t(), new_command_list}`. That is the new command list with the next
  command dequeued.

  If there is no more commands to run this return `nil`
  """
  @spec next_command(t()) :: {Command.t(), t()} | nil
  def next_command(command_list) do
    case :queue.out(command_list.queue) do
      {:empty, _} ->
        nil

      {{:value, command}, new_queue} ->
        {command, %{command_list | queue: new_queue}}
    end
  end
end
