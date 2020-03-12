defmodule VintageNetMobile.Chatscript do
  @moduledoc false

  @doc """
  Return the standard chatscript prologue

  This includes:

  1. Abort conditions
  2. Timeout
  3. Connection report
  4. Command mode entry (+++ and AT command check)
  5. Disconnect (ATH)
  6. Reset to factory defaults (ATZ)
  7. Send result codes (ATQ0) - NOTE: This should be redundant since ATZ resets to defaults

  Nearly all chatscripts start with this sequence or something very similar
  """
  @spec prologue(non_neg_integer()) :: String.t()
  def prologue(timeout \\ 10) do
    """
    ABORT 'BUSY'
    ABORT 'NO CARRIER'
    ABORT 'NO DIALTONE'
    ABORT 'NO DIAL TONE'
    ABORT 'NO ANSWER'
    ABORT 'DELAYED'
    TIMEOUT #{timeout}
    REPORT CONNECT
    "" +++
    "" AT
    OK ATH
    OK ATZ
    OK ATQ0
    """
  end

  @doc """
  Return the text to switch into ppp mode
  """
  @spec connect(non_neg_integer()) :: String.t()
  def connect(pdp_context \\ 1) do
    """
    OK ATDT*99***#{pdp_context}#
    CONNECT ''
    """
  end

  @doc """
  Output a basic default chatscript.

  This is useful if all you need is a basic chatscript. If you have more
  complex and custom needs you will not want to use this.
  """
  @spec default([VintageNetMobile.service_provider_info()]) :: String.t()
  def default(service_providers) do
    [
      prologue(),
      """
      OK ATQ0
      #{pdp_contexts(service_providers)}
      """,
      connect()
    ]
    |> IO.iodata_to_binary()
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
