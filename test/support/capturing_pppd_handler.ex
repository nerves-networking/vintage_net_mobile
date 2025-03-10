# SPDX-FileCopyrightText: 2020 Frank Hunleth
# SPDX-FileCopyrightText: 2020 Matt Ludwigs
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VintageNetMobile.CapturingPPPDHandler do
  @behaviour VintageNetMobile.ToElixir.PPPDHandler
  @moduledoc false

  @impl true
  def ip_up(ifname, env) do
    record(ifname, :ip_up, env)
  end

  @impl true
  def ip_down(ifname, env) do
    record(ifname, :ip_down, env)
  end

  @impl true
  def ip_pre_up(ifname, env) do
    record(ifname, :ip_pre_up, env)
  end

  @impl true
  def ipv6_up(ifname, env) do
    record(ifname, :ipv6_up, env)
  end

  @impl true
  def ipv6_down(ifname, env) do
    record(ifname, :ipv6_down, env)
  end

  @impl true
  def auth_up(ifname, env) do
    record(ifname, :auth_up, env)
  end

  @impl true
  def auth_down(ifname, env) do
    record(ifname, :auth_down, env)
  end

  @doc """
  Return captured calls
  """
  def get() do
    Agent.get(__MODULE__, fn x -> x end)
  end

  @doc """
  Clear out captured calls
  """
  def clear() do
    maybe_start()
    Agent.update(__MODULE__, fn _messages -> [] end)
  end

  defp record(ifname, op, info) do
    maybe_start()
    Agent.update(__MODULE__, fn messages -> [{ifname, op, info} | messages] end)
  end

  defp maybe_start() do
    case Process.whereis(__MODULE__) do
      nil ->
        {:ok, _pid} = Agent.start(fn -> [] end, name: __MODULE__)
        :ok

      _ ->
        :ok
    end
  end
end
