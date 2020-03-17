defmodule VintageNetMobile.Modem.UtilsTest do
  use ExUnit.Case

  alias VintageNetMobile.Modem.Utils

  test "requires one provider" do
    input = %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: QuectelBG96,
        service_providers: []
      }
    }

    assert_raise ArgumentError, fn -> Utils.require_a_service_provider(input) end
  end

  test "requires provider to have an apn" do
    input = %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: QuectelBG96,
        service_providers: [%{not_apn: "asdf"}]
      }
    }

    assert_raise ArgumentError, fn -> Utils.require_a_service_provider(input) end
  end

  test "requires provider to have multiple fields" do
    input = %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: QuectelBG96,
        service_providers: [%{apn: "asdf", another: "something"}]
      }
    }

    Utils.require_a_service_provider(input, [:apn])
    Utils.require_a_service_provider(input, [:apn, :another])

    assert_raise ArgumentError, fn ->
      Utils.require_a_service_provider(input, [:apn, :another, :yet_another])
    end

    assert_raise ArgumentError, fn -> Utils.require_a_service_provider(input, [:yet_another]) end
  end
end
