defmodule VintageNetMobile.ASUCalculatorTest do
  use ExUnit.Case
  alias VintageNetMobile.ASUCalculator

  test "computes gsm dbm" do
    assert ASUCalculator.from_gsm_asu(2).dbm == -109
    assert ASUCalculator.from_gsm_asu(9).dbm == -95
    assert ASUCalculator.from_gsm_asu(15).dbm == -83
    assert ASUCalculator.from_gsm_asu(30).dbm == -53

    assert ASUCalculator.from_gsm_asu(99).dbm == -113

    # Bad values
    assert ASUCalculator.from_gsm_asu(-100).dbm == -113
    assert ASUCalculator.from_gsm_asu(31).dbm == -53
  end

  test "computes gsm bars" do
    assert ASUCalculator.from_gsm_asu(2).bars == 1
    assert ASUCalculator.from_gsm_asu(9).bars == 1
    assert ASUCalculator.from_gsm_asu(14).bars == 2
    assert ASUCalculator.from_gsm_asu(15).bars == 3
    assert ASUCalculator.from_gsm_asu(30).bars == 4
    assert ASUCalculator.from_gsm_asu(99).bars == 0
  end
end
