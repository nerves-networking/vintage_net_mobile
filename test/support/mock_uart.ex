defmodule VintageNetMobileTest.MockUART do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [self()], opts)
  end

  def open(server, tty_name, opts \\ []) do
    GenServer.call(server, {:open, tty_name, opts})
  end

  def write(server, what) do
    GenServer.call(server, {:write, what})
  end

  @impl true
  def init([pid]) do
    {:ok, %{pid: pid, tty_name: "", response_map: %{}}}
  end

  @impl true
  def handle_call({:open, tty_name, opts}, _from, state) do
    response_map = Keyword.get(opts, :response_map, %{})
    new_state = %{state | tty_name: tty_name, response_map: response_map}
    {:reply, :ok, new_state}
  end

  def handle_call({:write, what}, _from, state) do
    case Map.get(state.response_map, what) do
      nil ->
        :ok

      responses ->
        Enum.each(responses, &send(state.pid, {:circuits_uart, state.tty_name, &1}))
    end

    {:reply, :ok, state}
  end
end
