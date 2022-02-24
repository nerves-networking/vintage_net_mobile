defmodule VintageNetMobile.Modem.Automatic.Discovery do
  @moduledoc false

  # A process for trying to discover a the type of modem and some basic
  # information to allow dynamic configuration items

  use GenServer

  alias Circuits.UART

  # the poll time for trying to enumerate the UARTS
  @enumeration_poll 3_000

  # To discover a which modem to use this process looks at the vendor ids and
  # manufacturer id to map to a `VintageNetMobile.Modem` implementation.

  # A source to find vendor and manufacturer ids is
  # https://elixir.bootlin.com/linux/latest/source/drivers/usb/serial/option.c#L245

  @quectel_vender_id 0x2C7C
  @telit_vendor_id 0x1BC7

  @modems %{
    {@telit_vendor_id, 0x1201} => VintageNetMobile.Modem.TelitLE910,
    {@quectel_vender_id, 0x0125} => VintageNetMobile.Modem.QuectelEC25,
    # map the EC21 to the EC25 as they work the same
    {@quectel_vender_id, 0x0121} => VintageNetMobile.Modem.QuectelEC25,
    {@quectel_vender_id, 0x0296} => VintageNetMobile.Modem.QuectelBG96
  }

  @typedoc """
  Init args

  - `:raw_config` - The RawConfig that contains configuration information to
    pass the discovered modem
  """
  @type init_arg() :: {:raw_config, VintageNet.Interface.RawConfig.t()}

  @doc """
  Start the discovery server
  """
  @spec start_link([init_arg()]) :: GenServer.on_start()
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(args) do
    {:ok, %{modem: nil, raw_config: args[:raw_config]}, {:continue, :detect_modem}}
  end

  @impl GenServer
  def handle_continue(:detect_modem, state) do
    {:noreply, do_detect_modem(state)}
  end

  @impl GenServer
  def handle_info(:detect_modem, state) do
    {:noreply, do_detect_modem(state)}
  end

  defp do_detect_modem(state) do
    case detect_modem() do
      nil ->
        Process.send_after(self(), :detect_modem, @enumeration_poll)
        state

      modem ->
        state = %{state | modem: modem}
        :ok = configure_vintage_net(state)

        state
    end
  end

  defp configure_vintage_net(state) do
    config = state.raw_config.source_config.vintage_net_mobile |> Map.put(:modem, state.modem)

    VintageNet.configure(
      state.raw_config.ifname,
      %{type: VintageNetMobile, vintage_net_mobile: config},
      persist: false
    )
  end

  defp detect_modem() do
    UART.enumerate()
    |> Enum.find_value(&known_modem/1)
  end

  defp known_modem({_tty, %{vendor_id: vid, product_id: pid}}) do
    Map.get(@modems, {vid, pid})
  end

  defp known_modem(_), do: nil
end
