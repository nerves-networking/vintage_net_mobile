defmodule VintageNetMobile.Chatscript do
  @moduledoc """
  Functions for working with chatscripts
  """

  @doc """
  Output a basic default chatscript.

  This is useful if all you need is a basic chatscript. If you have more
  complex and custom needs you will not want to use this.
  """
  @spec default([VintageNetMobile.service_provider_info()]) :: binary()
  def default(service_providers) do
    """
    ABORT 'BUSY'
    ABORT 'NO CARRIER'
    ABORT 'NO DIALTONE'
    ABORT 'NO DIAL TONE'
    ABORT 'NO ANSWER'
    ABORT 'DELAYED'
    TIMEOUT 10
    REPORT CONNECT

    "" AT

    OK ATH

    OK ATZ

    OK ATQ0

    #{pdp_contexts(service_providers)}
    OK ATDT*99***1#

    CONNECT ''
    """
  end

  @doc """
  Make the chatscript path for the interface
  """
  @spec path(binary(), keyword()) :: binary()
  def path(ifname, opts) do
    Path.join(Keyword.fetch!(opts, :tmpdir), "chatscript.#{ifname}")
  end

  defp pdp_contexts(service_providers) do
    {pdp_context_str, _} =
      Enum.reduce(service_providers, {"", 1}, fn provider, {pdp_context_str, pdp_id} ->
        %{apn: apn} = provider

        pdp_context_str =
          pdp_context_str <>
            """
            OK AT+CGDCONT=#{pdp_id},"IP","#{apn}"
            """

        {pdp_context_str, pdp_id + 1}
      end)

    pdp_context_str
  end
end
