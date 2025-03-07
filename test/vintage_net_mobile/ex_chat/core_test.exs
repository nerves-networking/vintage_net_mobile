# SPDX-FileCopyrightText: 2020 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VintageNetMobile.ExChat.CoreTest do
  use ExUnit.Case

  alias VintageNetMobile.ExChat.Core

  test "initialization" do
    state = Core.init()
    assert Core.pending_request_count(state) == 0
  end

  test "single notification" do
    state = Core.init()
    {state, _actions} = Core.register(state, "+CSQ:", :test_csq_handler)
    {state, actions} = Core.process(state, "+CSQ: 21,99")

    assert actions == [{:notify, "+CSQ: 21,99", :test_csq_handler}]
    assert Core.pending_request_count(state) == 0
  end

  test "multiple notifications" do
    state = Core.init()
    {state, _actions} = Core.register(state, "+CSQ:", :test_csq_handler)
    {state, _actions} = Core.register(state, "+CREG:", :test_creg_handler)

    {state, actions} = Core.process(state, "+CREG: 1,\"1234\",\"0011223\",7")
    assert actions == [{:notify, "+CREG: 1,\"1234\",\"0011223\",7", :test_creg_handler}]

    {state, actions} = Core.process(state, "+CSQ: 21,99")
    assert actions == [{:notify, "+CSQ: 21,99", :test_csq_handler}]

    {state, actions} = Core.process(state, "+CREG: 1,\"1234\",\"56789AB\",7")
    assert actions == [{:notify, "+CREG: 1,\"1234\",\"56789AB\",7", :test_creg_handler}]

    assert Core.pending_request_count(state) == 0
  end

  test "sending a command" do
    state = Core.init()
    {state, actions} = Core.send(state, "AT+CSQ", :sender_placeholder)

    assert [{:start_timer, 10_000, _ref}, {:send, "AT+CSQ"}] = actions
    assert Core.pending_request_count(state) == 1

    {state, []} = Core.process(state, "+CSQ: 21, 99")
    {state, actions} = Core.process(state, "OK")

    assert [:stop_timer, {:reply, {:ok, []}, :sender_placeholder}] = actions
    assert Core.pending_request_count(state) == 0
  end

  test "sending a command that gets a response" do
    state = Core.init()
    {state, actions} = Core.send(state, "ATI", :sender_placeholder)

    assert [{:start_timer, 10_000, _ref}, {:send, "ATI"}] = actions
    assert Core.pending_request_count(state) == 1

    # Actual ATI response with echo on
    {state, []} = Core.process(state, "ATI\r")
    {state, []} = Core.process(state, "Quectel")
    {state, []} = Core.process(state, "BG96")
    {state, []} = Core.process(state, "Revision: BG96MAR02A07M1G")
    {state, []} = Core.process(state, "")
    {state, actions} = Core.process(state, "OK")

    assert [
             :stop_timer,
             {:reply, {:ok, ["ATI\r", "Quectel", "BG96", "Revision: BG96MAR02A07M1G"]},
              :sender_placeholder}
           ] = actions

    assert Core.pending_request_count(state) == 0
  end

  test "command errors" do
    state = Core.init()
    {state, actions} = Core.send(state, "AT+CSQ", :sender_placeholder)

    assert [{:start_timer, 10_000, _ref}, {:send, "AT+CSQ"}] = actions

    {state, actions} = Core.process(state, "BUSY")

    assert [:stop_timer, {:reply, {:error, "BUSY"}, :sender_placeholder}] = actions
    assert Core.pending_request_count(state) == 0
  end

  test "command queueing" do
    state = Core.init()

    # First command
    {state, actions} = Core.send(state, "AT+CSQ", :sender_placeholder)

    assert [{:start_timer, 10_000, _ref}, {:send, "AT+CSQ"}] = actions

    # Second command (queued)
    {state, actions} = Core.send(state, "AT+COPS?", :sender_placeholder2)

    assert [] == actions
    assert Core.pending_request_count(state) == 2

    # Third command (queued)
    {state, actions} = Core.send(state, "AT+CFUN", :sender_placeholder3)

    assert [] == actions
    assert Core.pending_request_count(state) == 3

    {state, []} = Core.process(state, "+CSQ: 21, 99")
    {state, actions} = Core.process(state, "OK")

    assert [
             :stop_timer,
             {:reply, {:ok, []}, :sender_placeholder},
             {:start_timer, 10_000, _ref},
             {:send, "AT+COPS?"}
           ] = actions

    assert Core.pending_request_count(state) == 2

    {state, []} = Core.process(state, "+COPS: 0,0,\"Twilio\",7")
    {state, actions} = Core.process(state, "OK")

    assert [
             :stop_timer,
             {:reply, {:ok, []}, :sender_placeholder2},
             {:start_timer, 10_000, _ref},
             {:send, "AT+CFUN"}
           ] = actions

    assert Core.pending_request_count(state) == 1

    {state, actions} = Core.process(state, "ERROR")
    assert [:stop_timer, {:reply, {:error, "ERROR"}, :sender_placeholder3}] = actions
    assert Core.pending_request_count(state) == 0
  end

  test "timeout" do
    state = Core.init()
    {state, actions} = Core.send(state, "AT+CSQ", :sender_placeholder)

    [{:start_timer, 10_000, timer_ref}, {:send, "AT+CSQ"}] = actions

    {state, actions} = Core.timeout(state, timer_ref)

    assert [{:reply, {:error, :timeout}, :sender_placeholder}] = actions
    assert Core.pending_request_count(state) == 0
  end

  test "sends next command after a timeout" do
    state = Core.init()
    {state, actions} = Core.send(state, "AT+CSQ", :sender_placeholder)
    [{:start_timer, 10_000, timer_ref}, {:send, "AT+CSQ"}] = actions
    {state, []} = Core.send(state, "AT+COPS?", :sender_placeholder2)
    assert Core.pending_request_count(state) == 2

    # Check that the timer is restarted for the next command
    {state, actions} = Core.timeout(state, timer_ref)

    assert [
             {:reply, {:error, :timeout}, :sender_placeholder},
             {:start_timer, 10_000, _ref},
             {:send, "AT+COPS?"}
           ] = actions

    assert Core.pending_request_count(state) == 1

    {state, []} = Core.process(state, "+COPS: 0,0,\"Twilio\",7")
    {state, actions} = Core.process(state, "OK")
    assert [:stop_timer, {:reply, {:ok, []}, :sender_placeholder2}] = actions
    assert Core.pending_request_count(state) == 0
  end

  test "ignores unknown timeouts" do
    state = Core.init()
    {state, actions} = Core.timeout(state, make_ref())

    assert actions == []
    assert Core.pending_request_count(state) == 0
  end

  test "ignores junk when waiting on a command" do
    state = Core.init()
    {state, actions} = Core.send(state, "AT+CSQ", :sender_placeholder)

    assert [{:start_timer, 10_000, _ref}, {:send, "AT+CSQ"}] = actions
    assert Core.pending_request_count(state) == 1

    # Ignored notification
    {state, []} = Core.process(state, "+RANDOM_STUFF")

    # Ignored blank line
    {state, []} = Core.process(state, "")

    # Not ignored "response"
    {state, []} = Core.process(state, "asdf")

    # Ignored blank line
    {state, []} = Core.process(state, "")

    {state, actions} = Core.process(state, "OK")

    assert [:stop_timer, {:reply, {:ok, ["asdf"]}, :sender_placeholder}] = actions
    assert Core.pending_request_count(state) == 0
  end

  test "send commands that don't have responses" do
    state = Core.init()
    {state, actions} = Core.send(state, "AT+NO_RESPONSE", :sender_placeholder, timeout: 0)

    assert actions == [{:send, "AT+NO_RESPONSE"}, {:reply, {:ok, []}, :sender_placeholder}]
    assert Core.pending_request_count(state) == 0
  end

  test "queuing works with no response commands" do
    state = Core.init()

    # First command
    {state, actions} = Core.send(state, "AT+CSQ", :sender_placeholder)

    assert [{:start_timer, 10_000, _ref}, {:send, "AT+CSQ"}] = actions

    # Second command (queued and no response)
    {state, actions} = Core.send(state, "AT+NO_RESPONSE", :sender_placeholder2, timeout: 0)

    assert [] == actions
    assert Core.pending_request_count(state) == 2

    # Third command (queued and no response)
    {state, actions} = Core.send(state, "AT+NO_RESPONSE2", :sender_placeholder3, timeout: 0)

    assert [] == actions
    assert Core.pending_request_count(state) == 3

    {state, []} = Core.process(state, "+CSQ: 21, 99")
    {state, actions} = Core.process(state, "OK")

    assert [
             :stop_timer,
             {:reply, {:ok, []}, :sender_placeholder},
             {:send, "AT+NO_RESPONSE"},
             {:reply, {:ok, []}, :sender_placeholder2},
             {:send, "AT+NO_RESPONSE2"},
             {:reply, {:ok, []}, :sender_placeholder3}
           ] = actions

    assert Core.pending_request_count(state) == 0
  end
end
