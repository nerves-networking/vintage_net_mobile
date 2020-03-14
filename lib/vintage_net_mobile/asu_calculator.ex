defmodule VintageNetMobile.ASUCalculator do
  @moduledoc """
  Convert raw ASU values to friendlier units

  See https://en.wikipedia.org/wiki/Mobile_phone_signal#ASU for
  more information.

  The following conversions are done:

  * dBm
  * Number of "bars" out of 4 bars
  """

  @typedoc """
  Number of bars out of 4 to show in a UI
  """
  @type bars :: 0..4

  @typedoc """
  dBm
  """
  @type dbm :: neg_integer()

  @typedoc """
  GSM ASU values

  ASU values map to RSSI. 99 means unknown
  """
  @type gsm_asu :: 0..31 | 99

  @typedoc """
  UMTS ASU values

  ASU values map to RSCP
  """
  @type umts_asu :: 0..90 | 255

  @typedoc """
  LTE ASU values

  ASU values map to RSRP

  https://arimas.com/78-rsrp-and-rsrq-measurement-in-lte/
  """
  @type lte_asu :: 0..97

  @doc """
  Compute signal level numbers from a GSM ASU

  The `AT+CSQ` command should report ASU values in this format.
  """
  @spec from_gsm_asu(gsm_asu()) :: %{asu: gsm_asu(), dbm: dbm(), bars: bars()}
  def from_gsm_asu(asu) do
    clamped_asu = clamp_gsm_asu(asu)
    %{asu: asu, dbm: gsm_asu_to_dbm(clamped_asu), bars: gsm_asu_to_bars(clamped_asu)}
  end

  defp gsm_asu_to_dbm(asu) when asu == 99, do: -113

  defp gsm_asu_to_dbm(asu) do
    asu * 2 - 113
  end

  defp gsm_asu_to_bars(asu) when asu == 99, do: 0
  defp gsm_asu_to_bars(asu) when asu <= 9, do: 1
  defp gsm_asu_to_bars(asu) when asu <= 14, do: 2
  defp gsm_asu_to_bars(asu) when asu <= 19, do: 3
  defp gsm_asu_to_bars(asu) when asu <= 30, do: 4

  # defp lte_rssi_to_bars(rssi) when rssi > -65, do: 4
  # defp lte_rssi_to_bars(rssi) when rssi > -75, do: 3
  # defp lte_rssi_to_bars(rssi) when rssi > -85, do: 2
  # defp lte_rssi_to_bars(_rssi), do: 1

  # Clamp ASU to the allowed values
  defp clamp_gsm_asu(asu) when asu < 0, do: 0
  defp clamp_gsm_asu(asu) when asu == 99, do: 99
  defp clamp_gsm_asu(asu) when asu > 30, do: 30
  defp clamp_gsm_asu(asu), do: asu
end
