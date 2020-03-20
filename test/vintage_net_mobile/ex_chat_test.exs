defmodule VintageNetMobile.ExChatTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  alias VintageNetMobile.ExChat

  test "can send a command and get a response" do
    tty_name = "ttyUSB2"
    responses = %{"AT+CSQ" => ["+CSQ: 99,9", "OK"]}

    start_supervised!(
      {ExChat,
       [tty: tty_name, uart: VintageNetMobileTest.MockUART, uart_opts: [response_map: responses]]}
    )

    us = self()
    :ok = ExChat.register(tty_name, "+CSQ:", fn message -> send(us, {:response, message}) end)
    assert :ok == ExChat.send(tty_name, "AT+CSQ")

    assert_receive {:response, "+CSQ: 99,9"}
  end

  test "error responses get returned" do
    tty_name = "ttyUSB2"
    responses = %{"AT+CSQ" => ["ERROR"]}

    start_supervised!(
      {ExChat,
       [tty: tty_name, uart: VintageNetMobileTest.MockUART, uart_opts: [response_map: responses]]}
    )

    assert {:error, "ERROR"} == ExChat.send(tty_name, "AT+CSQ")
  end

  test "best effort errors are logged" do
    tty_name = "ttyUSB2"
    responses = %{"AT+CSQ" => ["ERROR"]}

    start_supervised!(
      {ExChat,
       [tty: tty_name, uart: VintageNetMobileTest.MockUART, uart_opts: [response_map: responses]]}
    )

    assert capture_log(fn -> :ok = ExChat.send_best_effort(tty_name, "AT+CSQ") end) =~
             ~r/Send "AT\+CSQ" failed/
  end

  test "that timeouts work" do
    tty_name = "ttyUSB2"
    responses = %{}

    start_supervised!(
      {ExChat,
       [tty: tty_name, uart: VintageNetMobileTest.MockUART, uart_opts: [response_map: responses]]}
    )

    assert {:error, :timeout} == ExChat.send(tty_name, "AT+CSQ", timeout: 10)
  end

  test "that partial responses get logged" do
    tty_name = "ttyUSB2"
    responses = %{"AT+CSQ" => [{:partial, "junk from a unit test"}, "+CSQ: 99,9", "OK"]}

    start_supervised!(
      {ExChat,
       [tty: tty_name, uart: VintageNetMobileTest.MockUART, uart_opts: [response_map: responses]]}
    )

    assert capture_log(fn -> :ok = ExChat.send(tty_name, "AT+CSQ") end) =~
             ~r/junk from a unit test/
  end

  test "normalizes tty names" do
    # This is mostly a sanity check that someone mixing and matching tty names
    # gets an error early on.

    start_supervised!({ExChat, [tty: "ttyUSB0", uart: VintageNetMobileTest.MockUART]})

    assert {:error, _anything} =
             start_supervised(
               {ExChat, [tty: "/dev/ttyUSB0", uart: VintageNetMobileTest.MockUART]}
             )
  end
end
