# VintageNetLTE

`VintageNetLTE` makes it easy to add cellular support to your device.

```elixir
def deps do
  [
    {:vintage_net_lte, "~> 0.1.0"}
  ]
end
```


```elixir
config :vintage_net,
  config: [
    {"ppp0",
     %{
       type: VintageNetLTE,
       modem: {VintageNetLTE.Huawei, [speed: 115200, serial: "/dev/ttyUSB0"]},
       chatscript: VintageNetLTE.Twillio
      }
     }
```

