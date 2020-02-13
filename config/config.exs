use Mix.Config

# Overrides for unit tests:
#
# * resolvconf: don't update the real resolv.conf
# * persistence_dir: use the current directory
# * bin_ip: just fail if anything calls ip rather that run it
config :vintage_net,
  resolvconf: "/dev/null",
  persistence_dir: "./test_tmp/persistence",
  bin_ip: "false"

config :vintage_net_lte,
  pppd_handler: VintageNetLTE.CapturingPPPDHandler,
  extra_modems: [
    VintageNetLTETest.CustomModem,
    VintageNetLTETest.HackedUpModem
  ],
  extra_service_providers: [
    {"Wilbur's LTE", apn: "wilbur.net"}
  ]
