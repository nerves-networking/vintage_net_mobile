defmodule VintageNetMobileTest.Utils do
  @moduledoc false
  @spec default_opts() :: keyword()
  def default_opts() do
    # Use the defaults in mix.exs, but normalize the paths to commands
    Application.get_all_env(:vintage_net)
    |> Keyword.merge(
      bin_chat: "chat",
      bin_dnsd: "dnsd",
      bin_ip: "ip",
      bin_killall: "killall",
      bin_mknod: "mknod",
      bin_pppd: "pppd",
      bin_udhcpc: "udhcpc",
      bin_udhcpd: "udhcpd",
      bin_wpa_supplicant: "wpa_supplicant"
    )
  end
end
