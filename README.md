# VintageNetMobile

[![Hex version](https://img.shields.io/hexpm/v/vintage_net_mobile.svg "Hex version")](https://hex.pm/packages/vintage_net_mobile)
[![API docs](https://img.shields.io/hexpm/v/vintage_net_mobile.svg?label=hexdocs "API docs")](https://hexdocs.pm/vintage_net_mobile/VintageNetMobile.html)
[![CircleCI](https://dl.circleci.com/status-badge/img/gh/nerves-networking/vintage_net_mobile/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/nerves-networking/vintage_net_mobile/tree/main)
[![REUSE status](https://api.reuse.software/badge/github.com/nerves-networking/vintage_net_mobile)](https://api.reuse.software/info/github.com/nerves-networking/vintage_net_mobile)

This library provides a `VintageNet` technology for using cellular modems.
Currently, it supports the following modems:

* Quectel BG96 - [`VintageNetMobile.Modem.QuectelBG96`](https://www.quectel.com/product/bg96.htm)
* Quectel EC25 - [`VintageNetMobile.Modem.QuectelEC25`](https://www.quectel.com/product/ec25.htm)
* u-blox TOBY L2 - [`VintageNetMobile.Modem.UbloxTOBYL2`](https://www.u-blox.com/en/product/toby-l2-series)
* Sierra Wireless HL8548 - [`VintageNetMobile.Modem.SierraHL8548`](https://source.sierrawireless.com/resources/airprime/hardware_specs_user_guides/airprime_hl8548_and_hl8548-g_product_technical_specification/)
* Huawei E3372 - [`VintageNetMobile.Modem.HuaweiE3372`](https://consumer.huawei.com/en/routers/e3372/)
* [ZTE MF833V] - does not need mobile driver, works with `VintageNetEthernet` when modem is configured to auto-connect

See the "Custom Modems" section for adding new modules.

To use this library, first add it to your project's dependency list:

```elixir
def deps do
  [
    {:vintage_net_mobile, "~> 0.11.1"}
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

## Automatic modem detection

If it is not known ahead of time what modem will be installed, the
`VintageNetMobile.Modem.Automatic` implementation can detect and configure it
for you. It works by waiting for the system to report a USB device with a known
vendor and product ID. Once one is found, it calls `VintageNet.configure/3` to
change the configuration from using the `Automatic` modem to the actual modem
implementation. It tells `VintageNet.configure/3` to not persist the
configuration so that the detection process runs again on the next boot.

Here's an example:

```elixir
  %{
    type: VintageNetMobile,
    vintage_net_mobile: %{
      modem: VintageNetMobile.Modem.Automatic,
      service_providers: [
        %{apn: "wireless.twilio.com"}
      ]
    }
  }
```

See [VintageNetMobile.Modem.Automatic.Discovery](lib/vintage_net_mobile/modem/automatic/discovery.ex)
for a list of modems that can be detected.

To check if your modem has been detected correctly you can run
`VintageNet.info()` and check the output configuration's `:modem` field:

```elixir
iex> VintageNet.info()
Interface ppp0
  Type: VintageNetMobile
  Power: Starting up/on (248378 ms left)
  Present: true
  State: :configured (0:01:13)
  Connection: :internet (21.8 s)
  Addresses: 111.11.111.111/32
  Configuration:
    %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: VintageNetMobile.Modem.TelitLE910,
        service_providers: [%{apn: "thebestapn"}]
      }
    }

```

## VintageNet Properties

In addition to the common `vintage_net` properties for all interface types, this
technology reports one or more of the following:

| Property      | Values         | Description                   |
| ------------- | -------------- | ----------------------------- |
| `signal_asu`  | `0-31,99`      | Reported Arbitrary Strength Unit (ASU) |
| `signal_4bars` | `0-4`         | The signal level in "bars"    |
| `signal_dbm`  | `-144 - -44`   | The signal level in dBm. Interpretation depends on the connection technology. |
| `signal_rssi` | `0-31` or `99` | An integer between 0-31 or 99 |
| `lac`         | `0-65533`      | The Location Area Code (lac) for the current cell |
| `cid`         | `0-268435455`  | The Cell ID (cid) for the current cell |
| `mcc`         | `0-999`        | Mobile Country Code for the network |
| `mnc`         | `0-999`        | Mobile Network Code for the network |
| `network`     | string         | The network operator's name |
| `access_technology` | string   | The technology currently in use to connect to the network |
| `band`        | string         | The frequency band in use |
| `channel`     | integer        | An integer that indicates the channel that's in use |
| `iccid`       | string         | The Integrated Circuit Card Identifier (ICCID) |
| `imsi`        | string         | The International Mobile Subscriber Identity (IMSI) |

Please check your modem implementation for which properties it supports or run
`VintageNet.get_by_prefix(["interface", "ppp0"])` and see what happens.

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

## Serial AT command debugging

When porting `vintage_net_mobile` to a new cell modem, it can be useful to
experiment with the modem directly. To do this, add a dependency to
[elixircom](https://github.com/mattludwigs/elixircom), rebuild, and then on the
device, you can do things like this:

```elixir
iex> Elixircom.run("/dev/ttyUSB2", speed: 115200)
```

Will allow you to run AT commands. To test everything is okay:

```elixir
iex> Elixircom.run("/dev/ttyUSB2", speed: 115200)
# type at and press enter

OK
```

Your modem should supply a complete list of AT commands. The following may be
useful:

| Command   | Description                                      |
| --------- | ------------------------------------------------ |
| at+csq    | Signal Strength                                  |
| at+csq=?  | Query supported signal strength format           |
| at+cfun?  | Level of functionality                           |
| at+cfun=? | Query supported functionality levels             |
| at+creg?  | Check if the modem has registered to a provider. |
| at+cgreg? | Same as above for some modems                    |
| at+qccid  | Query to obtain the Integrated Circuit Card Identifier             |
| at+cimi   | Query to obtain the International Mobile Subscriber Identity             |

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
