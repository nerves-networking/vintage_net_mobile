defmodule VintageNetLTE.SignalStrengthTest do
  use ExUnit.Case

  alias VintageNet.PropertyTable
  alias VintageNetLTE.SignalStrength

  test "converts rssi into dBm" do
    dbms = for rssi <- 2..30, do: SignalStrength.rssi_to_dbm(rssi)

    assert -53 == Enum.max(dbms)
    assert -109 == Enum.min(dbms)
  end

  test "sets the property table for the signal strength correctly" do
    :ok = SignalStrength.set_signal_properties(24, "ppp0_test")

    assert 24 ==
             PropertyTable.get(VintageNet, ppp0_property("ppp0_test", "signal_rssi"))

    assert -65 == PropertyTable.get(VintageNet, ppp0_property("ppp0_test", "signal_dbm"))
  end

  defp ppp0_property(ifname, property) do
    ["interface", ifname, "lte", property]
  end
end
