# VintageNetMobile

[![Hex version](https://img.shields.io/hexpm/v/vintage_net_mobile.svg "Hex version")](https://hex.pm/packages/vintage_net_mobile)
[![API docs](https://img.shields.io/hexpm/v/vintage_net_mobile.svg?label=hexdocs "API docs")](https://hexdocs.pm/vintage_net_mobile/VintageNetMobile.html)
[![CircleCI](https://circleci.com/gh/nerves-networking/vintage_net_mobile.svg?style=svg)](https://circleci.com/gh/nerves-networking/vintage_net_mobile)
[![Coverage Status](https://coveralls.io/repos/github/nerves-networking/vintage_net_mobile/badge.svg?branch=master)](https://coveralls.io/github/nerves-networking/vintage_net_mobile?branch=master)

This library provides a `VintageNet` technology for using cellular modems.
Currently, it supports the following modems:

* Quectel BG96 - [`VintageNetMobile.Modem.QuectelBG96`](https://www.quectel.com/product/bg96.htm)
* Quectel EC25 - [`VintageNetMobile.Modem.QuectelEC25`](https://www.quectel.com/product/ec25.htm)
* ublox TOBY L2 - [`VintageNetMobile.Modem.UbloxTOBYL2`](https://www.u-blox.com/en/product/toby-l2-series)
* Sierra Wireless HL8548 - [`VintageNetMobile.Modem.SierraHL8548`](https://source.sierrawireless.com/resources/airprime/hardware_specs_user_guides/airprime_hl8548_and_hl8548-g_product_technical_specification/)

See the "Custom Modems" section for adding new modules.

To use this library, first add it to your project's dependency list:

```elixir
def deps do
  [
    {:vintage_net_mobile, "~> 0.1.2"}
  ]
end
```

You will then need to configure `VintageNet`. All cellular modems currently show
up on "ppp0", so configurations look like this:

```elixir
VintageNet.configure("ppp0", %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: your_modem,
        service_providers: your_service_providers
      }
    })
```

The `:modem` key should be set to your modem implementation. Cellular modems
tend to be very similar. If `vintage_net_mobile` doesn't support your modem, see
the customizing section. It may just be a copy/paste away.

The `:service_providers` key should be set to information provided by each of
your service providers. It is common that this is a list of one item.
Circumstances may require you to list more than one, though. Additionally, modem
implementations may require more information. (It's also possible to hard-code
the service provider in the modem implementation as a hack. In that case, this
key isn't used and should be set to an empty list. This is useful when your
cellular modem provides instructions that magically work and the AT commands
that they give are confusing.)

Information for each service provider is a map with some or all of the following
fields:

* `:apn` (required) - e.g., `"access_point_name"`
* `:usage` (optional) - `:eps_bearer` (LTE) or `:pdp` (UMTS/GPRS)

Your service provider should provide you with the information that you need to
connect. Often it is just an APN. The Gnome project provides a database of
[service provider
information](https://wiki.gnome.org/Projects/NetworkManager/MobileBroadband/ServiceProviders)
that may also be useful.

Here's an example with a service provider list:

```elixir
  %{
    type: VintageNetMobile,
    vintage_net_mobile: %{
      modem: your_modem,
      service_providers: [
        %{apn: "wireless.twilio.com"}
      ]
    }
  }
```

## Custom modems

`VintageNetMobile` allows you add custom modem implementations if the built-in
ones don't work for you. See the `VintageNetMobile.Modem` behaviour.

In order to implement a modem, you will need:

1. Instructions for connecting to the modem via your Linux. Sometimes this
   involves `usb_modeswitch` or knowing which serial ports the modem exposes.
2. Example chat scripts. These are lists of `AT` commands and their expected
   responses for configuring the service provider and entering `PPP` mode.
3. (Optional) Instructions for checking the signal strength when connected.

One strategy is to see if there's an existing modem that looks similar to yours
and modify it.

## System requirements

These requirements are believed to be the minimum needed to be added to the
official Nerves systems.

### Linux kernel

Enable PPP and drivers for your modem:

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

`VintageNetMobile` makes it easy to add cellular support to your device.
