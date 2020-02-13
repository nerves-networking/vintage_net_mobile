defmodule VintageNetLTE.ServiceProviderTest do
  use ExUnit.Case

  alias VintageNetLTE.ServiceProviders

  test "supports Twilio" do
    assert ServiceProviders.apn!("Twilio") == "wireless.twilio.com"
  end

  test "raises when a unsupported provider is given" do
    assert_raise ArgumentError, fn ->
      ServiceProviders.apn!("NotAProvider")
    end
  end
end
