defmodule VintageNetLTE.Huawei do
  @behaviour VintageNetLTE.Modem

  def modules() do
    [
      "huawei_cdc_ncm",
      "option",
      "bsd_comp",
      "ppp_deflate"
    ]
  end

  def before_up_cmds() do
    [
      {"usb_modeswitch", ["-v", "12d1", "-p", "14fe", "-J"]}
    ]
  end
end
