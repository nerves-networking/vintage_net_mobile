defmodule VintageNetLTE.ToElixir.Server do
  use GenServer
  require Logger

  alias VintageNetLTE.ToElixir.PPPDHandler

  @moduledoc """
  This GenServer routes messages from C and shell scripts to the appropriate
  places in VintageNetLTE.
  """

  @doc """
  Start the GenServer.
  """
  @spec start_link(Path.t()) :: GenServer.on_start()
  def start_link(path) do
    GenServer.start_link(__MODULE__, path, name: __MODULE__)
  end

  @impl true
  def init(path) do
    # Blindly try to remove an old file just in case it exists from a previous run
    _ = File.rm(path)
    _ = File.mkdir_p(Path.dirname(path))

    {:ok, socket} = :gen_udp.open(0, [:local, :binary, {:active, true}, {:ip, {:local, path}}])

    state = %{path: path, socket: socket}
    {:ok, state}
  end

  @impl true
  def handle_info({:udp, socket, _, 0, data}, %{socket: socket} = state) do
    data
    |> :erlang.binary_to_term()
    |> normalize_argv0()
    |> dispatch()

    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    # Try to clean up
    _ = File.rm(state.path)
  end

  defp normalize_argv0({[argv0 | args], env}) do
    {[Path.basename(argv0) | args], env}
  end

  defp dispatch({["ip-up", ifname, _tty, _baud, _our_ip, _their_ip], env}) do
    PPPDHandler.dispatch(:ip_up, ifname, env)
    :ok
  end

  defp dispatch({["ip-down", ifname, _tty, _baud, _our_ip, _their_ip], env}) do
    PPPDHandler.dispatch(:ip_down, ifname, env)
    :ok
  end

  defp dispatch({["ip-pre-up", ifname, _tty, _baud, _our_ip, _their_ip], env}) do
    PPPDHandler.dispatch(:ip_pre_up, ifname, env)
    :ok
  end

  defp dispatch({["ipv6-up", ifname, _tty, _baud, _our_ip, _their_ip], env}) do
    PPPDHandler.dispatch(:ipv6_up, ifname, env)
    :ok
  end

  defp dispatch({["ipv6-down", ifname, _tty, _baud, _our_ip, _their_ip], env}) do
    PPPDHandler.dispatch(:ipv6_down, ifname, env)
    :ok
  end

  defp dispatch({["auth-up", ifname, _peer_name, _user_name, _tty], env}) do
    PPPDHandler.dispatch(:auth_up, ifname, env)
    :ok
  end

  defp dispatch({["auth-down", ifname, _peer_name, _user_name, _tty], env}) do
    PPPDHandler.dispatch(:auth_down, ifname, env)
    :ok
  end

  defp dispatch({["ppp_to_elixir" | args], env}) do
    _ = Logger.debug("ppp_to_elixir: Args=#{inspect(args)}, Env=#{inspect(env)}")
    :ok
  end

  defp dispatch(unknown) do
    _ = Logger.error("ppp_to_elixir: dropping unknown report '#{inspect(unknown)}''")
    :ok
  end
end
