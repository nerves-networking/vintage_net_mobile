# VintageNetMobile

[![Hex version](https://img.shields.io/hexpm/v/vintage_net_mobile.svg "Hex version")](https://hex.pm/packages/vintage_net_mobile)
[![API docs](https://img.shields.io/hexpm/v/vintage_net_mobile.svg?label=hexdocs "API docs")](https://hexdocs.pm/vintage_net_mobile/VintageNetMobile.html)
[![CircleCI](https://circleci.com/gh/nerves-networking/vintage_net_mobile.svg?style=svg)](https://circleci.com/gh/nerves-networking/vintage_net_mobile)
[![Coverage Status](https://coveralls.io/repos/github/nerves-networking/vintage_net_mobile/badge.svg?branch=master)](https://coveralls.io/github/nerves-networking/vintage_net_mobile?branch=master)

A `VintageNet` technology for using mobile connections.

```elixir
def deps do
  [
    {:vintage_net_mobile, "~> 0.1.2"}
  ]
end
```

To get this technology running with VintageNet run the following:

```elixir
    VintageNet.configure(
      "ppp0",
      %{
        type: VintageNetMobile,
        modem: your_modem,
        service_provider: your_service_provider
      }
    )
```

or add this to your `config.exs`:

```elixir
config :vintage_net,
  config: [
    {"ppp0", %{type: VintageNetMobile, modem: your_modem, service_providers: [
      "pimentocheese",
    ]}}
  ]
```

A good resource to find APNs for your service provider is:
https://gitlab.gnome.org/GNOME/mobile-broadband-provider-info/-/blob/master/serviceproviders.xml

When using a custom modem you can leave out the `:service_providers` field and
hard code the service provider and protocol information into a custom
chatscript for you modem.

See "Custom Modems" section for more information on how to do that.

Supported modems:

* `"Quectel BG96"`
* `"Quectel EC25-AF"`

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

## Custom Modems

To use a custom modem implementation `VintageNetMobile` exposes the
`VintageNetMobile.Modem` behaviour. This is also the way to provide custom
chatscripts. `VitnageNetMobile` does provide a simple default chatscript
via the `VintageNetMobile.Chatscript` module, however if you are trying handle
more advanced configuration you will probably want to provide your own
chatscript.

### Example

```elixir
defmodule MyModem do
  @behaviour VintageNetMobile.Modem

  alias VintageNetMobile.{Chatscript, PPPDConfig}

  @impl true
  def add_raw_config(vintage_raw_config, provided_config, vintage_net_env) do
    ifname = vintagenet_raw_config.ifname

    files = [{Chatscript.path(ifname, opts), chatscript()}]

    up_cmds = [
      {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]}
    ]

    child_specs = [
      {ATRunner, [tty: "ttyUSB2", speed: 9600]},
      {SignalMonitor, [ifname: ifname, tty: "ttyUSB2"]}
    ]

    %RawConfig{
      raw_config
      | files: files,
        up_cmds: up_cmds,
        require_interface: false,
        child_specs: child_specs
    }
    |> PPPDConfig.add_child_spec("ttyUSB3", 9600, opts)
  end

  @impl true
  def ready(), do: true

  @impl true
  def validate_config(_provided_config) do
    :ok
  end

  defp chatscript() do
    """
    ....
    """
  end
end
```

```elixir
config :vintage_net,
  config: [
    {"ppp0", %{type: VintageNetMobile, modem: MyModem}}
  ]
```

Notice how we did not need to provide any services providers for a custom modem
as we can provide the necessary information in the custom chatscript.

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

