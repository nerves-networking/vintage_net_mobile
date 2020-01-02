# VintageNetLTE

## Dev Notes

Manually setting up an LTE connection with a Huawei module


```
:ok = VintageNetLTE.write_chat_script()
:ok = VintageNetLTE.run_mknod()
:ok = VintageNetLTE.run_usbmodeswitch()
VintageNetLTE.run_pppd
```


`VintageNetLTE` makes it easy to add cellular support to your device.

```elixir
def deps do
  [
    {:vintage_net_lte, "~> 0.1.0"}
  ]
end
```


