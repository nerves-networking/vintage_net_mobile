defmodule VintageNetLTE.Chatscript do
  @moduledoc """
  Functions for working with chatscripts
  """

  @doc """
  Output a basic default chatscript.

  This is useful if all you need is a basic chatscript. If you have more
  complex and custom needs you will not want to use this.
  """
  @spec default(binary()) :: binary()
  def default(apn) do
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

    OK AT+CGDCONT=1,"IP","#{apn}"

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
end
