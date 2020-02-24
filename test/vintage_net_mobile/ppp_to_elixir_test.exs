defmodule VintageNetMobile.PPPDToElixirTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias VintageNetMobile.CapturingPPPDHandler

  test "can send message from C" do
    assert capture_log(fn ->
             to_elixir = Application.app_dir(:vintage_net_mobile, ["priv", "ppp_to_elixir"])
             System.cmd(to_elixir, ["hello", "from", "a", "c", "program"])
             Process.sleep(100)
           end) =~ "[debug] ppp_to_elixir: Args=[\"hello\", \"from\", \"a\", \"c\", \"program\"]"
  end

  test "ppp_to_elixir filters out unsupported environment variables" do
    CapturingPPPDHandler.clear()
    to_elixir = Application.app_dir(:vintage_net_mobile, ["priv", "ppp_to_elixir"])

    {_, 0} =
      System.cmd(
        to_elixir,
        ["ppp0", "/dev/ttyUSB0", "115200", "162.175.202.224", "10.177.0.34"],
        arg0: "ip-up",
        env: [
          {"DEVICE", "/dev/ttyUSB0"},
          {"DNS1", "10.177.0.34"},
          {"DNS2", "10.177.0.210"},
          {"IFNAME", "ppp0"},
          {"IPLOCAL", "162.175.202.224"},
          {"ORIG_UID", "0"},
          {"PPPD_PID", "278"},
          {"PPPLOGNAME", "root"},
          {"SPEED", "115200"},
          {"USEPEERDNS", "1"},
          {"HELLO", "WORLD"}
        ]
      )

    Process.sleep(100)

    [{_ifname, _reported_callback, env}] = CapturingPPPDHandler.get()

    refute env[:HELLO]
  end

  test "pppd handler notifies Elixir" do
    CapturingPPPDHandler.clear()
    to_elixir = Application.app_dir(:vintage_net_mobile, ["priv", "ppp_to_elixir"])

    {_, 0} =
      System.cmd(
        to_elixir,
        ["ppp0", "/dev/ttyUSB0", "115200", "162.175.202.224", "10.177.0.34"],
        arg0: "ip-up",
        env: [
          {"DEVICE", "/dev/ttyUSB0"},
          {"DNS1", "10.177.0.34"},
          {"DNS2", "10.177.0.210"},
          {"IFNAME", "ppp0"},
          {"IPLOCAL", "162.175.202.224"},
          {"ORIG_UID", "0"},
          {"PPPD_PID", "278"},
          {"PPPLOGNAME", "root"},
          {"SPEED", "115200"},
          {"USEPEERDNS", "1"}
        ]
      )

    Process.sleep(100)

    [{ifname, reported_callback, env}] = CapturingPPPDHandler.get()

    assert reported_callback == :ip_up
    assert ifname == "ppp0"

    assert env[:DEVICE] == "/dev/ttyUSB0"
    assert env[:SPEED] == "115200"
    assert env[:DNS1] == "10.177.0.34"
    assert env[:DNS2] == "10.177.0.210"
    assert env[:IPLOCAL] == "162.175.202.224"
    assert env[:ORIG_UID] == "0"
    assert env[:PPPD_PID] == "278"
    assert env[:PPPLOGNAME] == "root"
    assert env[:SPEED] == "115200"
    assert env[:USEPEERDNS] == "1"
  end
end
