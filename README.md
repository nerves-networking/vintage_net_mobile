# VintageNetLTE

## Dev Notes

Manually setting up an LTE connection with a Huawei module:

```
:ok = VintageNetLTE.write_chat_script()
:ok = VintageNetLTE.run_mknod()
:ok = VintageNetLTE.run_usbmodeswitch()
VintageNetLTE.run_pppd("/dev/ttyUSB0")
```

If you are running this on a nerves device and have [elixircom](https://github.com/mattludwigs/elixircom) installed:

```
iex> Elixircom.run("/dev/ttyUSB2", speed: 115200)
```

Will allow you to run AT commands. To test everything is okay:

```
iex> Elixircom.run("/dev/ttyUSB2", speed: 115200)
# type at and press enter

OK
```


`VintageNetLTE` makes it easy to add cellular support to your device.

```elixir
def deps do
  [
    {:vintage_net_lte, "~> 0.1.0"}
  ]
end
```


