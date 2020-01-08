# VintageNetLTE

This has only been tested with Huawei and Twilio connections and is not fully
functioning yet.

System requirements:

* `pppd`
* `ip`
* `usb_modeswitch` (At least for the Huawei)

To get this technology running with VintageNet run the following:

```
VintageNetLTE.setup()
VintageNet.configure("ppp0", %{type: VintageNetLTE})
```

## Current status

Figuring out how to ensure up commands are ran before
`pppd`. There seems to be an issue if the interface is not present.

Right now the `VintageNetLTE.setup` call does what the `up_cmds` configuration
should be doing.

Still have to get routing working through VintageNet.

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


## Serial AT command debugging

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

Command    | Description
-----------|-----------------------
at+csq     | Signal Strength
at+csq=?   | Query supported signal strength format
at+cfun?   | Level of functionality 
at+cfun=?  | Query supported functionality levels


`VintageNetLTE` makes it easy to add cellular support to your device.

```elixir
def deps do
  [
    {:vintage_net_lte, "~> 0.1.0"}
  ]
end
```


