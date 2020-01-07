# VintageNetLTE

This has only been tested with Huawei and Twilio connections.

## Dev Notes

Manually setting up an LTE connection with a Huawei module:

```
:ok = VintageNetLTE.setup() 
VintageNetLTE.run_pppd("/dev/ttyUSB0")
```

If you need some extra debug information about the PPP packets that are being
sent you can run `run_pppd/2` like so:

`VintageNetLTE.run_pppd("/dev/ttyUSB0", debug: true)`


### Setting routes

Currently `ppp` tries to set the routes be will fail with this error log.

```
pppd[314]: not replacing existing default route via 192.168.0.1
```

So if you try to run `ping "google.com", ifname: "ppp0"` it will not work.

To solve this add the route manually:

```
cmd "ip route add default dev ppp0"
```

Then to check if everything is working you can try to run the above `ping` command
again.


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


