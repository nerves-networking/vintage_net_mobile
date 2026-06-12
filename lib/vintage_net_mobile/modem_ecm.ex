# SPDX-FileCopyrightText: 2020 Frank Hunleth
# SPDX-FileCopyrightText: 2022 Matt Ludwigs
# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2026 Digit
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VintageNetMobile.ModemECM do
  use GenServer
  require Logger
  alias VintageNetMobile.ExChat

  defmodule State do
    @moduledoc false

    defstruct ifname: nil, tty: nil, apn: nil, ready: false, phase: nil
  end

  @spec start_link([keyword()]) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(opts) do
    ifname = Keyword.fetch!(opts, :ifname)
    tty = Keyword.fetch!(opts, :tty)
    apn = Keyword.fetch!(opts, :apn)

    us = self()

    ExChat.register(tty, "+QNETDEVSTATUS", fn message ->
      send(us, {:handle_dev_status, message})
    end)

    Process.send_after(us, :setup_modem, 500)

    {:ok, %State{ifname: ifname, tty: tty, apn: apn, ready: false, phase: :liveness_check}}
  end

  @impl GenServer
  def handle_info(:setup_modem, %{phase: :liveness_check} = state) do
    Logger.debug("Checking Modem liveness...")

    case ExChat.send(state.tty, "AT") do
      {:ok, _} ->
        ExChat.send_best_effort(state.tty, "ATH")
        ExChat.send_best_effort(state.tty, "ATZ")
        ExChat.send_best_effort(state.tty, "ATQ0")
        Process.send_after(self(), :setup_modem, 500)
        {:noreply, %{state | phase: :apn_setup}}

      _ ->
        Process.send_after(self(), :setup_modem, 500)
        {:noreply, state}
    end
  end

  def handle_info(:setup_modem, %{phase: :apn_setup} = state) do
    Logger.debug("Setting modem APN...")

    cmd = "AT+CGDCONT=1,\"IP\",\"#{state.apn}\""

    case ExChat.send(state.tty, cmd) do
      {:ok, _} ->
        Process.send_after(self(), :setup_modem, 500)
        {:noreply, %{state | phase: :usb_net_config}}

      _ ->
        Process.send_after(self(), :setup_modem, 500)
        {:noreply, state}
    end
  end

  def handle_info(:setup_modem, %{phase: :usb_net_config} = state) do
    Logger.debug("Setting up modem USBNET...")

    with {:ok, _} <- ExChat.send(state.tty, "AT+QCFG=\"usbnet\",1") do
      Logger.debug("Modem configured for USBNET (ECM), starting data session...")
      ExChat.send_best_effort(state.tty, "AT+QNETDEVCTL=1,1,1")
      {:noreply, %{state | phase: :done}}
    else
      _ ->
        Process.send_after(self(), :setup_modem, 500)
        {:noreply, state}
    end
  end

  def handle_info({:handle_dev_status, message}, state) do
    if message == "+QNETDEVSTATUS: 1" do
      Logger.debug("USBNET set complete!")
      {:noreply, %{state | ready: true}, :hibernate}
    else
      Logger.error(
        "Unexpected QNETDEVSTATUS from modem: #{message}, retying configuration in 10 seconds"
      )

      Process.send_after(self(), :setup_modem, 10_000)
      {:noreply, %{state | phase: :liveness_check}}
    end
  end
end
