defmodule VintageNetMobile.ExChat.Core do
  @moduledoc false

  alias VintageNetMobile.ExChat.{Request, State}

  @type what :: any()
  @type who :: any()

  @typedoc """
  ExChat returns actions that the caller should do on its behalf

  Actions include anything that has side effects and are needed
  to keep the core functions pure.
  """
  @type action ::
          {:notify, what(), who()}
          | {:reply, what(), who()}
          | {:send, iodata()}
          | {:start_timer, non_neg_integer(), reference()}
          | :stop_timer

  @type result :: {State.t(), [action()]}

  @type send_options :: [
          success: String.t(),
          errors: [String.t()],
          timeout: non_neg_integer()
        ]

  @doc """
  Initialize chat handling
  """
  @spec init() :: State.t()
  def init() do
    %State{}
  end

  @doc """
  Register a notification handler

  The notification type sound be a string like "+CSQ:". Responses from the
  modem that start with that prefix will be posted to the `who`.
  """
  @spec register(State.t(), String.t(), who()) :: result()
  def register(%State{} = state, type, who) do
    listener = {type, who}
    new_state = %State{state | listeners: [listener | state.listeners]}

    {new_state, []}
  end

  @doc """
  Send a request to the modem

  If there's an outstanding request, this one will be queued for later.
  If the request has a 0 timeout or has a `:success` option set to the
  empty string, then no reply from the modem is expected. A `{:reply, what, who}`
  action will still be generated when the command is sent.
  """
  @spec send(State.t(), iodata(), who(), send_options()) :: result()
  def send(%State{} = state, message, who, opts \\ []) do
    request = Request.new(message, who, opts)

    case state.request do
      nil ->
        send_request(state, request)

      _anything ->
        new_state = %{state | queued_requests: :queue.in(request, state.queued_requests)}
        {new_state, []}
    end
  end

  @doc """
  Notify that a previously set timer has expired
  """
  @spec timeout(State.t(), reference()) :: result()
  def timeout(%State{request_timer: timeout_ref} = state, timeout_ref) do
    action = {:reply, {:error, :timeout}, state.request.id}
    {new_state, more_actions} = maybe_send_next_request(state)
    {new_state, [action | more_actions]}
  end

  def timeout(state, _unknown_timeout_ref) do
    {state, []}
  end

  @doc """
  Process a line received from the modem
  """
  @spec process(State.t(), String.t()) :: result()
  def process(%State{} = state, message) do
    actions = handle_notifications(message, state)

    {new_state, more_actions} = handle_replies(message, state)

    {new_state, actions ++ more_actions}
  end

  @doc """
  Return the number of pending requests
  """
  @spec pending_request_count(State.t()) :: non_neg_integer()
  def pending_request_count(state) do
    case state.request do
      nil -> 0
      _something -> 1 + :queue.len(state.queued_requests)
    end
  end

  defp handle_notifications(message, state) do
    Enum.flat_map(
      state.listeners,
      fn {prefix, who} ->
        if String.starts_with?(message, prefix) do
          [{:notify, message, who}]
        else
          []
        end
      end
    )
  end

  defp handle_replies(_message, %{request: nil} = state) do
    {state, []}
  end

  defp handle_replies(message, %{request: request} = state) do
    cond do
      message == request.success ->
        actions = [:stop_timer, {:reply, :ok, request.id}]
        {new_state, more_actions} = maybe_send_next_request(state)
        {new_state, actions ++ more_actions}

      message in request.errors ->
        actions = [:stop_timer, {:reply, {:error, message}, request.id}]
        {new_state, more_actions} = maybe_send_next_request(state)
        {new_state, actions ++ more_actions}

      true ->
        {state, []}
    end
  end

  defp maybe_send_next_request(state) do
    case :queue.out(state.queued_requests) do
      {:empty, _} ->
        new_state = %{state | request: nil, request_timer: nil}
        {new_state, []}

      {{:value, request}, new_queue} ->
        new_state = %{state | queued_requests: new_queue}
        send_request(new_state, request)
    end
  end

  # Requests without responses
  defp send_request(state, %{timeout: timeout, success: success} = request)
       when timeout <= 0 or success == "" do
    actions = [{:send, request.request}, {:reply, :ok, request.id}]

    # See if another request has been queued.
    {new_state, more_actions} = maybe_send_next_request(state)
    {new_state, actions ++ more_actions}
  end

  # Normal case where we expect a response
  defp send_request(state, request) do
    request_timer = make_ref()

    actions = [
      {:start_timer, request.timeout, request_timer},
      {:send, request.request}
    ]

    new_state = %{state | request: request, request_timer: request_timer}
    {new_state, actions}
  end
end
