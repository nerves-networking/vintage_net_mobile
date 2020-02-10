defmodule VintageNetLTE.Modems.Table do
  @moduledoc """
  The list of modem names with provider names that point to a module that
  implements the `VintageNetLTE.Modem` behaviour.

  You can add custom modem support by passing `:extra_modems` field:

  ```elixir
  Table.start_link(extra_modems: [{"MyModem", "Verizon", MyModemModule}])
  ```
  """

  use Agent

  @typedoc """
  Define a modem specification

  This is a tuple that has the modem name, provider name, and the module that
  implements the `VintageNetLTE.Modem` behaviour.
  """
  @type modem_def :: {String.t(), String.t(), module()}

  @type opt :: {:extra_modems, [modem_def()]}

  @spec start_link([opt]) :: Agent.on_start()
  def start_link(opts) do
    Agent.start_link(fn -> table(opts) end, name: __MODULE__)
  end

  @doc """
  Look up the modem module for the given modem name and provider name
  """
  @spec lookup(String.t(), String.t()) :: module() | nil
  def lookup(modem, provider) do
    Agent.get(__MODULE__, &lookup(&1, modem, provider))
  end

  defp table(opts) do
    extra_modems = Keyword.get(opts, :extra_modems)

    Enum.reduce(extra_modems, default_modems(), fn {modem, provider, module}, acc ->
      [{{modem, provider}, module} | acc]
    end)
  end

  defp lookup(table, modem, provider) do
    Enum.find_value(table, fn
      {{^modem, ^provider}, modem_module} -> modem_module
      _ -> nil
    end)
  end

  defp default_modems() do
    [
      {{"Quectel BG96", "Twilio"}, VintageNetLTE.Modems.QuectelBG96}
    ]
  end
end
