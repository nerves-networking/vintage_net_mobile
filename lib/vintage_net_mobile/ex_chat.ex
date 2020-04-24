defmodule VintageNetMobile.ExChat do
  @moduledoc """
  Send commands to your modem and get notifications

  This module is used by the "monitor" modules for reporting modem and
  connection status.

  It can be handy to debug modems too. If you'd like to send commands and
  receive notifications from the IEx prompt, here's what to do:

  ```elixir
  require Logger
  RingLogger.attach
  tty_name = "ttyUSB2" # set to your AT command interface
  VintageNetMobile.ExChat.register(tty_name, "+", fn m -> Logger.debug("Got: " <> inspect(m)) end)
  VintageNetMobile.ExChat.send(tty_name, "AT+CSQ")
  ```

  To reset the registrations, `VintageNet.deconfigure/2` and
  `VintageNet.configure/3` your modem.
  """

  alias VintageNetMobile.ExChat.Core

  # This limits the restart rate for this GenServer on tty errors.
  # Errors usually mean the interface is going away and vintage_net
  # will clean things up soon. If nothing else, the UART won't be
  # pegged by restarts and the logs won't be filled with errors.
  @error_delay 1000

  @typedoc """
  The options for the ATCommand server are:

  * `:speed` - the speed of the serial connection
  * `:tty` - the tty name for sending AT commands
  * `:uart` - use an alternative UART-provider (for testing)
  * `:uart_opts` - additional options to pass to UART.open
  """
  @type opt ::
          {:speed, non_neg_integer()}
          | {:tty, String.t()}
          | {:uart, module()}
          | {:uart_opts, keyword()}

  use GenServer
  require Logger

  @spec start_link([opt]) :: GenServer.on_start()
  def start_link(opts) do
    tty_name = Keyword.fetch!(opts, :tty)
    GenServer.start_link(__MODULE__, opts, name: server_name(tty_name))
  end

  @doc """
  Send a command to the modem

  On success, this returns a list of the lines received back from the modem.
  """
  @spec send(binary(), iodata(), Core.send_options()) :: {:ok, [binary()]} | {:error, any()}
  def send(tty_name, command, options \\ []) do
    # Make sure we wait long enough for the command to be processed by the modem
    command_timeout = Keyword.get(options, :timeout, 10000) + 500

    GenServer.call(server_name(tty_name), {:send, command, options}, command_timeout)
  end

  @doc """
  Helper for sending commands to the modem as best effort

  This function always succeeds. Failed commands log errors, but that's it. This
  is useful for monitoring operations where intermittent failures should be logged,
  but really aren't worth dealing with.
  """
  @spec send_best_effort(binary(), iodata(), Core.send_options()) :: :ok
  def send_best_effort(tty_name, command, options \\ []) do
    case send(tty_name, command, options) do
      {:ok, _response} ->
        :ok

      error ->
        _ = Logger.warn("Send #{inspect(command)} failed: #{inspect(error)}. Ignoring...")
        :ok
    end
  end

  @doc """
  Register a callback function for reports
  """
  @spec register(binary(), binary(), function()) :: :ok
  def register(tty_name, type, callback) do
    GenServer.call(server_name(tty_name), {:register, type, callback})
  end

  @impl true
  def init(opts) do
    speed = Keyword.get(opts, :speed, 115_200)
    tty_name = Keyword.fetch!(opts, :tty)
    uart = Keyword.get(opts, :uart, Circuits.UART)
    uart_opts = Keyword.get(opts, :uart_opts, [])

    {:ok, uart_ref} = uart.start_link()

    all_uart_opts =
      [
        speed: speed,
        framing: {Circuits.UART.Framing.Line, separator: "\r\n"},
        rx_framing_timeout: 500
      ] ++ uart_opts

    {:ok,
     %{uart: uart, uart_ref: uart_ref, tty_name: tty_name, core: Core.init(), timer_ref: nil},
     {:continue, all_uart_opts}}
  end

  @impl true
  def handle_continue(uart_opts, state) do
    case state.uart.open(state.uart_ref, state.tty_name, uart_opts) do
      :ok ->
        {:noreply, state}

      {:error, error} ->
        _ = Logger.warn("vintage_net_mobile: can't open #{state.tty_name}: #{inspect(error)}")
        Process.sleep(@error_delay)
        {:stop, :tty_error, state}
    end
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
  def handle_info({:circuits_uart, tty_name, {:partial, fragment}}, state) do
    _ = Logger.warn("vintage_net_mobile: dropping junk from #{tty_name}: #{inspect(fragment)}")
    {:noreply, state}
  end

  def handle_info({:circuits_uart, tty_name, {:error, error}}, state) do
    _ = Logger.warn("vintage_net_mobile: error from #{tty_name}: #{inspect(error)}")
    Process.sleep(@error_delay)
    {:stop, :tty_error, state}
  end

  def handle_info({:circuits_uart, _tty_name, message}, state) do
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
    :ok = state.uart.write(state.uart_ref, what)
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

  defp server_name("/dev/" <> tty_name) do
    server_name(tty_name)
  end

  defp server_name(tty_name) do
    Module.concat([__MODULE__, tty_name])
  end
end
