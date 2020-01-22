defmodule VintageNetLTE.SignalStrength do
  @moduledoc """
  Functionality for working with the signal strength of an LTE modem
  """

  alias VintageNet.PropertyTable

  @doc """
  Get the dbm value from the RSSI value

  This is calculated by: `worse_dBm + rssi * 2

  Where the `worse_dBm` is `-113`

  The best possible RSSI value is `31`.

  For more resources about the conversion formula see section 6.3
  from https://www.quectel.com/UploadImage/Downlad/Quectel_BG96_AT_Commands_Manual_V2.1.pdf
  """
  @spec rssi_to_dbm(non_neg_integer()) :: integer() | :unknown
  def rssi_to_dbm(99), do: :unknown

  def rssi_to_dbm(rssi) when rssi <= 31 do
    -113 + rssi * 2
  end

  @doc """
  Set the signal strength related properties on VintageNet's property table.

  Supported properties:

  * `signal_rssi` - a value that represents the percent of signal strength
    `0-30`
  * `signal_dbm` - a value that represents the dBm of the signal strength
    `-109..-53`
  """
  @spec set_signal_properties(non_neg_integer(), VintageNet.ifname()) :: :ok
  def set_signal_properties(rssi, ifname) do
    dbm = rssi_to_dbm(rssi)
    :ok = set_rssi_property(rssi, ifname)
    :ok = set_dbm_property(dbm, ifname)

    :ok
  end

  defp set_dbm_property(signal_dbm, ifname) do
    PropertyTable.put(VintageNet, ["interface", ifname, "lte", "signal_dbm"], signal_dbm)
  end

  defp set_rssi_property(rssi, ifname) do
    PropertyTable.put(VintageNet, ["interface", ifname, "lte", "signal_rssi"], rssi)
  end
end
