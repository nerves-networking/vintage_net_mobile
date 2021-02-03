defmodule VintageNetMobile.Modem.HuaweiE3372.Modeswitch do
  @moduledoc """
  VintageNetMobile PowerManager to handle the HuaweiE3372 modem
  """

  require Logger
  @behaviour VintageNet.PowerManager

  @impl VintageNet.PowerManager
  def init(_args) do
    {:ok, {}}
  end

  @impl VintageNet.PowerManager
  def power_on(state) do
    # Do whatever is necessary to turn the network interface on
    _ = safe_cmd("usb_modeswitch", ["-v 12d1", "-p 14fe", "-X"])
    {:ok, state, 5000}
  end

  @impl VintageNet.PowerManager
  def start_powering_off(state) do
    # If there's a graceful power off, start it here and return
    # the max time it takes.
    {:ok, state, 0}
  end

  @impl VintageNet.PowerManager
  def power_off(state) do
    # Disable the network interface
    _ = safe_cmd("usb_modeswitch", ["-v 12d1", "-p 155e", "-X"])

    {:ok, state, 0}
  end

  @impl VintageNet.PowerManager
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp safe_cmd(cmd, args) do
    do_safe_cmd(System.find_executable(cmd), args)
  end

  defp do_safe_cmd(nil, _args) do
    Logger.error("usb_modeswitch not found in path")
    {:error, :enoent}
  end

  defp do_safe_cmd(path, args) do
    case System.cmd(path, args) do
      {_output, 0} ->
        :ok

      {output, _status} ->
        Logger.error("Huawei E3372 modeswitch failed with '#{output}'")
        {:error, :error_exit}
    end
  end
end
