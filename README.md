# VintageNetLTE

[![Hex version](https://img.shields.io/hexpm/v/vintage_net_lte.svg "Hex version")](https://hex.pm/packages/vintage_net_lte)
[![API docs](https://img.shields.io/hexpm/v/vintage_net_lte.svg?label=hexdocs "API docs")](https://hexdocs.pm/vintage_net_lte/VintageNetEthernet.html)
[![CircleCI](https://circleci.com/gh/nerves-networking/vintage_net_lte.svg?style=svg)](https://circleci.com/gh/nerves-networking/vintage_net_lte)
[![Coverage Status](https://coveralls.io/repos/github/nerves-networking/vintage_net_lte/badge.svg?branch=master)](https://coveralls.io/github/nerves-networking/vintage_net_lte?branch=master)

To get this technology running with VintageNet run the following:

```elixir
    VintageNet.configure(
      "ppp0",
      %{
        type: VintageNetLTE,
        modem: your_modem,
        service_provider: your_service_provider
      }
    )
```

or add this to your `config.exs`:

```elixir
config :vintage_net,
  config: [
    {"ppp0", %{type: VintageNetLTE, modem: your_modem, service_provider: your_service_provider}}
  ]
```

Supported modems:

* `"Quectel BG96"`
* `"Quectel EC25-AF"`

Supported service providers:

* `"Twilio"`

## System requirements

These requirements are believed to be the minimum needed to be added to the
official Nerves systems.

### Linux kernel

Enable PPP and drivers for your LTE modem:

```text
CONFIG_PPP=m
CONFIG_PPP_BSDCOMP=m
CONFIG_PPP_DEFLATE=m
CONFIG_PPP_FILTER=y
CONFIG_PPP_MPPE=m
CONFIG_PPP_MULTILINK=y
CONFIG_PPP_ASYNC=m
CONFIG_PPP_SYNC_TTY=m
CONFIG_USB_NET_CDC_NCM=m
CONFIG_USB_NET_HUAWEI_CDC_NCM=m
CONFIG_USB_NET_QMI_WWAN=m
CONFIG_USB_SERIAL_OPTION=m
```

### Buildroot (nerves_defconfig)

Both `pppd` and `usb_modeswitch` are needed in the `nerves_defconfig`:

```text
BR2_PACKAGE_USB_MODESWITCH=y
BR2_PACKAGE_PPPD=y
BR2_PACKAGE_PPPD_FILTER=y
```

### Busybox

Add the following to your `nerves_defconfig`:

```text
BR2_PACKAGE_BUSYBOX_CONFIG_FRAGMENT_FILES="${NERVES_DEFCONFIG_DIR}/busybox.fragment"
```

and then create `busybox.fragment` with the following:

```text
CONFIG_MKNOD=y
CONFIG_WC=y
```

## Custom Modems

`VintageNetLTE` allows you add custom modem implementations if the built-in
implementations don't work for you:

```elixir
config :vintage_net_lte,
  extra_modems: [MyBestLTEEverModem]
```

Modem implementations need to implement the `VintageNetLTE.Modem` behaviour.

This will allow your modem to tie into `VintageNetLTE` without having relying
on our supported providers. This is useful for highly custom chatscripts or
non-generic modem implementations.

## VintageNet Properties

In addition to the common `vintage_net` properties for all interface types, this technology reports the following:

| Property      | Values         | Description                   |
| ------------- | -------------- | ----------------------------- |
| `signal_rssi` | `0-31` or `99` | An integer between 0-31 or 99 |

## Serial AT command debugging

If you are running this on a nerves device and have
[elixircom](https://github.com/mattludwigs/elixircom) installed:

```elixir
iex> Elixircom.run("/dev/ttyUSB2", speed: 115200)
```

Will allow you to run AT commands. To test everything is okay:

```elixir
iex> Elixircom.run("/dev/ttyUSB2", speed: 115200)
# type at and press enter

OK
```

| Command   | Description                                      |
| --------- | ------------------------------------------------ |
| at+csq    | Signal Strength                                  |
| at+csq=?  | Query supported signal strength format           |
| at+cfun?  | Level of functionality                           |
| at+cfun=? | Query supported functionality levels             |
| at+creg?  | Check if the modem has registered to a provider. |
| at+cgreg? | Same as above for some modems                    |

`VintageNetLTE` makes it easy to add cellular support to your device.

```elixir
def deps do
  [
    {:vintage_net_lte, "~> 0.1.0"}
  ]
end
```
