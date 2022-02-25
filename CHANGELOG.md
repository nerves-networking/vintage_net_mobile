# Changelog

## [v0.11.0] - 2022-02-25

### Added

* Support for the Telit LE910 modem (see `VintageNetMobile.Modem.TelitLE910`)
* Support modem implementation selection at runtime. See
  `VintageNetMobile.Modem.Automatic` for more details.

## [v0.10.4] - 2022-02-16

### Fixed

* Fixed dropped `pppd` notifications to Elixir when using Nerves systems with
  `glibc v2.33` and later. This affects Nerves toolchains with version numbers
  `v1.4.2` and later.

## v0.10.3

* Changes
  * Allow `muontrap v1.0.0` to be used

## v0.10.2

* Changes
  * Support `vintage_net v0.11.x` as well.

## v0.10.1

* Bug fixes
  * `vintage_net v0.10.4` had a fix to route setup to remove a DHCP renewal
    hiccup and a routing API change that only affected this project. This
    updates to the new API to remove a deprecation warning. That also means that
    at least `vintage_net v0.10.4` is required now and the deps force this.

## v0.10.0

This release contains no code changes. It only updates the `vintage_net`
dependency to allow `vintage_net v0.10.0` to be used.

## v0.9.2

* New features
  * Huawei E3372 support - Thanks to Hans Pagh for contributing his
    implementation.

* Bug fixes
  * Handle more types of CREG responses. This should reduce warnings from the
    CellMonitor code

## v0.9.1

* New features
  * Support non-default tty paths for Quectel modems

## v0.9.0

* New features
  * Add initial support for using the `VintageNet.PowerManager`to manage the
    power to cellular modems. This allows `VintageNet` to power on and off a
    modem as needed and if it becomes unresponsive. To use this, you will need
    to provide an implementation of `VintageNet.PowerManager` that can control
    the GPIO (or whatever) connections that enable power and can send
    appropriate UART commands to power off. This only has been tested with
    Quectel BG96 and EC25 modems, but should be applicable to all modems.
  * Synchronize with vintage_net v0.9.0's networking program path API update

## v0.8.0

(Skipping version numbers to make the version match `vintage_net` for ease of
remembering which versions are compatible.)

* New features
  * Add `:chatscript_additions` option to the modem configuration to support
    arbitrary chatscript lines so that application-specific customizations don't
    require you to make a custom modem. Of course, if you have an option of
    general interest, please continue to make PRs.
  * Support vintage_net v0.8.0's `required_ifnames` API update. This cleans up
    some modem detection for non-usb_modswitch modems. If you have a fork of
    this project, you'll need to update it. See commit 06456c3bc/PR #66 for how
    the supported modems were changed.

* Bug fixes
  * Cleaned up handling of PPP disconnections. Amazingly, OTP supervision could
    recover some of this, but the logs were really ugly and more work was done
    than needed.

## v0.2.3

* Updates
  * Allow `muontrap` v0.6.0 to be used since the breaking change doesn't affect
    `vintage_net_mobile`
  * Force `vintage_net` v0.7.9 or later to pull in PPP IP address fix

## v0.2.2

* New features
  * Added a "monitor" for reporting a SIM card's ICCID and IMSI. These are
    useful for debugging issues with service providers. Currently this is
    only available on the BG96, but can easily be added to other modems as
    testing permits.

## v0.2.1

This release has improvements and bug fixes throughout, but primarily for the
Quectel EC25 (LTE Cat 4 modem) and Quectel BG96 (LTE Cat M1/NB1 modem)

* New features
  * Network connection stats for the EC25 and BG96 modems. This lets you see how
    the modem connected (GSM, UMTS, LTE, etc) and to which cell tower (cell id,
    lac, mcc, mnc). This is useful for debug and geolocation.
  * Improved signal strength reporting. The reports are now in ASU (arbitrary
    strength units), dBm, and bars. Bars ranges from 0 bars (no connection) to 4
    bars (strong signal) similar to a cell phone

## v0.2.0

This release has significant changes to the configuration API and
`VintageNetMobile.Modem` behaviour. No migration from the old version is
supported. We don't expect to majorly change the API in future releases. Updates
will be more incremental. The plan is to add configuration migrations so that
devices in the field can continue to work between `vintage_net_mobile` updates.

To upgrade, find the module documentation for your modem. There will be a
configuration example that should look familiar.

## v0.1.2

* Bug fix
  * Prevent `VintageNet` from trying to run `ppp` before a modem is ready.

## v0.1.1

* Bug fixes
  * Fix a timing issue when `VintageNet` would try to call a `VintageNetMobile`
    process before it was started

## v0.1.0

Initial `vintage_net_mobile` release.

[v0.11.0]: https://github.com/nerves-networking/vintage_net_mobile/compare/v0.10.4...v0.11.0
[v0.10.4]: https://github.com/nerves-networking/vintage_net_mobile/compare/v0.10.3...v0.10.4

