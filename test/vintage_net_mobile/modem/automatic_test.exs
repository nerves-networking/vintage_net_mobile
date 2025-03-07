# SPDX-FileCopyrightText: 2022 Frank Hunleth
# SPDX-FileCopyrightText: 2022 Matt Ludwigs
# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2024 Jon Ringle
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VintageNetMobile.Modem.AutomaticTest do
  use ExUnit.Case, async: true

  alias VintageNet.Interface.RawConfig
  alias VintageNetMobile.Modem.Automatic
  alias VintageNetMobile.Modem.Automatic.Discovery

  test "create LTE configuration" do
    input = %{
      type: VintageNetMobile,
      vintage_net_mobile: %{
        modem: Automatic,
        service_providers: [%{apn: "choosethislteitissafe"}, %{apn: "wireless.twilio.com"}]
      }
    }

    # RawConfig that will be passed to the discovered modem
    base_raw_config = %RawConfig{
      ifname: "ppp0",
      type: VintageNetMobile,
      source_config: input,
      required_ifnames: ["wwan0"],
      up_cmds: [],
      down_cmds: [],
      files: [],
      child_specs: []
    }

    output = %RawConfig{
      ifname: "ppp0",
      type: VintageNetMobile,
      source_config: input,
      required_ifnames: ["wwan0"],
      up_cmds: [
        {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]},
        {:run_ignore_errors, "mkdir", ["-p", "/var/run/pppd/lock"]}
      ],
      down_cmds: [
        {:fun, PropertyTable, :delete_matches, [VintageNet, ["interface", "ppp0", "mobile"]]}
      ],
      files: [],
      child_specs: [
        {Discovery, [raw_config: base_raw_config]}
      ]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end
end
