defmodule VintageNetLTE.ATBufferTest do
  use ExUnit.Case

  alias VintageNetLTE.ATBuffer

  test "handles a new report" do
    buffer = []
    report = "+CSQ: 24,0"

    assert {:continue, [{:csq_report, {24, 0}}]} == ATBuffer.handle_report(buffer, report)
  end

  test "handles report completion" do
    buffer = [{:csq_report, {24, 0}}]

    assert {:complete, buffer} == ATBuffer.handle_report(buffer, "OK")
  end

  test "handles completion when there are extra reports" do
    buffer = []

    {:continue, new_buffer} = ATBuffer.handle_report(buffer, "+CSQ: 56, 12")
    {:continue, new_buffer} = ATBuffer.handle_report(new_buffer, "Quectel")
    {:continue, new_buffer} = ATBuffer.handle_report(new_buffer, "Revision: BG96MAR01A01M1G")

    expected_buffer = [
      {:csq_report, {56, 12}},
      {:unsupported, "Quectel"},
      {:unsupported, "Revision: BG96MAR01A01M1G"}
    ]

    assert {:complete, expected_buffer} == ATBuffer.handle_report(new_buffer, "OK")
  end

  test "allows filtering on report type" do
    buffer = []

    {:continue, new_buffer} = ATBuffer.handle_report(buffer, "+CSQ: 56, 12")
    {:continue, new_buffer} = ATBuffer.handle_report(new_buffer, "Quectel")
    {:continue, new_buffer} = ATBuffer.handle_report(new_buffer, "Revision: BG96MAR01A01M1G")

    assert [{:csq_report, {56, 12}}] == ATBuffer.filter_reports(new_buffer, :csq_report)
  end
end
