defmodule VintageNetLTE.ATRunner do
  @moduledoc """
  Send AT command_list to modem
  """

  alias VintageNetLTE.ATRunner.CommandList
  alias VintageNetLTE.ATRunner.CommandList.Command

  @typedoc """
  The options for the ATCommand server are:

  * `:speed` - the speed of the serial connection
  * `:tty` - the tty to send AT command to
  """
  @type opt :: {:speed, non_neg_integer()} | {:tty, String.t()}

  use GenServer
  alias Circuits.UART

  defmodule State do
    @moduledoc false

    @type t :: %__MODULE__{
            uart: pid(),
            tty: binary(),
            command_timeout_ref: nil | reference(),
            command_list: CommandList.t(),
            buffer: [binary()]
          }

    defstruct uart: nil,
              tty: nil,
              command_timeout_ref: nil,
              command_list: %CommandList{},
              buffer: []
  end

  @spec start_link([opt]) :: GenServer.on_start()
  def start_link(opts) do
    tty = Keyword.fetch!(opts, :tty)
    GenServer.start_link(__MODULE__, opts, name: server_name(tty))
  end

  @doc """
  Send an AT command to the modem

  This takes the tty name, the AT command to send, the AT command wait for, and
  a timeout.

  The default timeout is 500 milliseconds
  """
  @spec send(binary(), binary(), binary() | nil, non_neg_integer()) :: {:ok, [binary()]}
  def send(tty, command, wait_for \\ nil, timeout \\ 500) do
    GenServer.call(server_name(tty), {:send, command, wait_for, timeout})
  end

  def stop(tty) do
    tty
    |> server_name()
    |> GenServer.stop()
  end

  @impl true
  def init(opts) do
    speed = Keyword.get(opts, :speed, 115_200)
    tty = Keyword.fetch!(opts, :tty)

    {:ok, uart} = UART.start_link()

    :ok =
      UART.open(uart, tty,
        speed: speed,
        framing: {UART.Framing.Line, separator: "\r\n"}
      )

    {:ok,
     %State{
       uart: uart,
       tty: tty
     }}
  end

  @impl true
  def handle_call({:send, command, wait_for, timeout}, from, state) do
    command = %Command{command: command, stop_response: wait_for, waiter: from, timeout: timeout}

    state =
      case CommandList.put(state.command_list, command) do
        {:queued, command_list} ->
          %{state | command_list: command_list}

        command_list ->
          timeout_ref = write_at_command(state.uart, command)
          %{state | command_list: command_list, command_timeout_ref: timeout_ref}
      end

    case wait_for do
      nil ->
        {:reply, :ok, state}

      _ ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:circuits_uart, _tty, ""}, state), do: {:noreply, state}

  def handle_info({:circuits_uart, _tty, at_response}, state) do
    case CommandList.handle_response(state.command_list, at_response) do
      {:complete, command, command_list} ->
        _ = Process.cancel_timer(state.command_timeout_ref)
        GenServer.reply(command.waiter, {:ok, Enum.reverse(state.buffer)})
        {:noreply, handle_next_command(state, command_list)}

      :continue ->
        {:noreply, %{state | buffer: [at_response | state.buffer]}}
    end
  end

  def handle_info(:timeout, state) do
    GenServer.reply(state.command_list.current_command.waiter, {:error, :timeout, state.buffer})
    {:noreply, handle_next_command(state)}
  end

  defp handle_next_command(state) do
    handle_next_command(state, state.command_list)
  end

  defp handle_next_command(state, command_list) do
    case CommandList.next_command(command_list) do
      nil ->
        %{state | command_list: command_list, buffer: [], command_timeout_ref: nil}

      {next_command, new_command_list} ->
        timeout_ref = write_at_command(state.uart, next_command)

        %{state | command_list: new_command_list, command_timeout_ref: timeout_ref}
    end
  end

  defp write_at_command(uart, command) do
    timeout_ref = set_timeout(command.timeout)
    :ok = UART.write(uart, command.command)

    timeout_ref
  end

  defp server_name("/dev/" <> tty) do
    server_name(tty)
  end

  defp server_name(tty) do
    Module.concat([__MODULE__, tty])
  end

  defp set_timeout(timeout) do
    Process.send_after(self(), :timeout, timeout)
  end
end
