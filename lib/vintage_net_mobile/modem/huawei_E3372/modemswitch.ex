
defmodule VintageNetMobile.Modem.HuaweiE3372.Modemswitch do
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
    try do
      System.cmd("usb_modeswitch", ["-v 12d1", "-p 14fe", "-X"])
    catch error ->
      Logger.debug("Modemswicth failed with #{error} ")
    after
      {:ok, state, 5000}
    end
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
    try do
      System.cmd("usb_modeswitch", ["-v 12d1", "-p 155e", "-X"])
    catch error ->
      Logger.debug("Modemswicth failed with #{error} ")
    after
      {:ok, state, 0}
    end
  end

  @impl VintageNet.PowerManager
  def handle_info(_msg, state) do
    {:ok, state}
  end
end
