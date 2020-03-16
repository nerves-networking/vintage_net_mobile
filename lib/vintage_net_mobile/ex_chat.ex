defmodule VintageNetMobile.ExChat do
  @moduledoc false

  alias VintageNetMobile.ExChat.Core

  @typedoc """
  The options for the ATCommand server are:

  * `:speed` - the speed of the serial connection
  * `:tty` - the tty to send AT command to
  """
  @type opt :: {:speed, non_neg_integer()} | {:tty, String.t()}

  use GenServer
  alias Circuits.UART
  require Logger

  @spec start_link([opt]) :: GenServer.on_start()
  def start_link(opts) do
    tty = Keyword.fetch!(opts, :tty)
    GenServer.start_link(__MODULE__, opts, name: server_name(tty))
  end

  @doc """
  Send a command to the modem

  """
  @spec send(binary(), iodata(), Core.send_options()) :: :ok | {:error, any()}
  def send(tty, command, options \\ []) do
    # Make sure we wait long enough for the command to be processed by the modem
    command_timeout = Keyword.get(options, :timeout, 10000) + 500

    GenServer.call(server_name(tty), {:send, command, options}, command_timeout)
  end

  @doc """
  Register a callback function for reports
  """
  @spec register(binary(), String.t(), function()) :: :ok
  def register(tty, type, callback) do
    GenServer.call(server_name(tty), {:register, type, callback})
  end

  @impl true
  def init(opts) do
    speed = Keyword.get(opts, :speed, 115_200)
    tty = Keyword.fetch!(opts, :tty)

    {:ok, uart} = UART.start_link()

    :ok =
      UART.open(uart, tty,
        speed: speed,
        framing: {UART.Framing.Line, separator: "\r\n"},
        rx_framing_timeout: 500
      )

    {:ok,
     %{
       uart: uart,
       tty: tty,
       core: Core.init(),
       timer_ref: nil
     }}
  end

  @impl true
  def handle_call({:send, command, options}, from, state) do
    {new_core_state, actions} = Core.send(state.core, command, from, options)

    new_state =
      %{state | core: new_core_state}
      |> run_actions(actions)

    {:noreply, new_state}
  end

  @impl true
  def handle_call({:register, type, callback}, _from, state) do
    {new_core_state, actions} = Core.register(state.core, type, callback)

    new_state =
      %{state | core: new_core_state}
      |> run_actions(actions)

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info({:circuits_uart, tty, {:partial, fragment}}, state) do
    _ = Logger.warn("vintage_net_mobile: dropping junk from #{tty}: #{inspect(fragment)}")
    {:noreply, state}
  end

  def handle_info({:circuits_uart, _tty, message}, state) do
    {new_core_state, actions} = Core.process(state.core, message)

    new_state =
      %{state | core: new_core_state}
      |> run_actions(actions)

    {:noreply, new_state}
  end

  def handle_info({:timeout, core_timer_ref}, state) do
    {new_core_state, actions} = Core.timeout(state.core, core_timer_ref)

    new_state =
      %{state | core: new_core_state, timer_ref: nil}
      |> run_actions(actions)

    {:noreply, new_state}
  end

  defp run_actions(state, actions) do
    Enum.reduce(actions, state, &run_action(&2, &1))
  end

  defp run_action(state, {:notify, what, who}) do
    apply(who, [what])
    state
  end

  defp run_action(state, {:reply, what, who}) do
    GenServer.reply(who, what)
    state
  end

  defp run_action(state, {:send, what}) do
    :ok = UART.write(state.uart, what)
    state
  end

  defp run_action(state, {:start_timer, timeout, core_timer_ref}) do
    timer_ref = Process.send_after(self(), {:timeout, core_timer_ref}, timeout)
    %{state | timer_ref: timer_ref}
  end

  defp run_action(state, :stop_timer) do
    _ = Process.cancel_timer(state.timer_ref)
    %{state | timer_ref: nil}
  end

  defp server_name("/dev/" <> tty) do
    server_name(tty)
  end

  defp server_name(tty) do
    Module.concat([__MODULE__, tty])
  end
end
