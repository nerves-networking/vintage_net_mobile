defmodule VintageNetLTE.ATRunner.CommandListTest do
  use ExUnit.Case

  alias VintageNetLTE.ATRunner.CommandList
  alias VintageNetLTE.ATRunner.CommandList.Command

  test "put a new command in the command list when empty" do
    command = %Command{command: "AT+CSQ", stop_response: "OK", waiter: self(), timeout: 1_000}
    command_list = %CommandList{}

    updated_command_list = CommandList.put(command_list, command)

    assert updated_command_list.current_command == command
  end

  test "put a new command in a command list that needs to be queued" do
    command = %Command{command: "AT+CSQ", stop_response: "OK", waiter: self(), timeout: 1_000}

    queued_command = %Command{
      command: "AT+QCSQ",
      stop_response: "OK",
      waiter: self(),
      timeout: 2_000
    }

    command_list = CommandList.put(%CommandList{}, command)
    assert {:queued, _command_list} = CommandList.put(command_list, queued_command)
  end

  test "get the next command when there is none" do
    assert nil == CommandList.next_command(%CommandList{})
  end

  test "get the next command when there is another command" do
    command = %Command{command: "AT+CSQ", stop_response: "OK", waiter: self(), timeout: 1_000}

    queued_command = %Command{
      command: "AT+QCSQ",
      stop_response: "OK",
      waiter: self(),
      timeout: 2_000
    }

    command_list = CommandList.put(%CommandList{}, command)
    {:queued, command_list} = CommandList.put(command_list, queued_command)

    assert {queued_command, _} = CommandList.next_command(command_list)
  end

  test "handle a command when a non-stopping response comes in" do
    command = %Command{command: "AT+CSQ", stop_response: "OK", waiter: self(), timeout: 1_000}
    command_list = CommandList.put(%CommandList{}, command)

    assert :continue == CommandList.handle_response(command_list, "KEEP GOING!")
  end

  test "handle a command when a stopping response comes in" do
    command = %Command{command: "AT+CSQ", stop_response: "OK", waiter: self(), timeout: 1_000}
    command_list = CommandList.put(%CommandList{}, command)

    assert {:complete, command, %CommandList{}} == CommandList.handle_response(command_list, "OK")
  end

  test "check if the command is done" do
    command = %Command{command: "AT+CSQ", stop_response: "OK", waiter: self(), timeout: 1_000}

    assert true == Command.stop_response?(command, "OK")
    assert false == Command.stop_response?(command, "KEEP GOING?")
  end
end
