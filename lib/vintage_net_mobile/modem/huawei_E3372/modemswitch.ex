
defmodule VintageNetMobile.Modem.HuaweiE3372.Modemeswitch do

  @behaviour VintageNet.PowerManager

  @impl VintageNet.PowerManager
  def init(_args) do
    {:ok, {}}
  end

  @impl VintageNet.PowerManager
  def power_on(state) do
    # Do whatever is necessary to turn the network interface on
    Toolshed.cmd("usb_modeswitch -v 12d1 -p 14fe -X")
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
    Toolshed.cmd("usb_modeswitch -v 12d1 -p 155e -X")
    {:ok, state, 0}
  end
