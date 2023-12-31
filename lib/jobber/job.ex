defmodule Jobber.Job do
  use GenServer, restart: :transient
  require Logger

  defstruct [:id, :max_retries, :work, retries: 0, status: :new]

  def init(args) do
    state = %__MODULE__{
      max_retries: Keyword.get(args, :max_retries, 3),
      work: Keyword.fetch!(args, :work)
    }

    {:ok, state, {:continue, :run}}
  end

  def handle_continue(:run, state) do
    new_state = state.work.() |> handle_job_result(state)

    if new_state.status == :error do
      Process.send_after(self(), :retry, 1000)

      {:noreply, new_state}
    else
      Logger.info("Job (#{new_state.id}) exited as #{new_state.status}")

      {:stop, :normal, new_state}
    end
  end

  def handle_info(:retry, state) do
    {:noreply, state, {:continue, :run}}
  end

  def start_link(args) do
    args =
      if Keyword.has_key?(args, :id) do
        args
      else
        Keyword.put(args, :id, random_job_id())
      end

    id = Keyword.get(args, :id)
    type = Keyword.get(args, :type)

    GenServer.start_link(__MODULE__, args, name: via(id, type))
  end

  defp handle_job_result({:ok, _}, state) do
    Logger.info("Job (#{state.id}) completed successfully")

    %__MODULE__{state | status: :done}
  end

  defp handle_job_result(:error, %{status: :new} = state) do
    Logger.warn("Job (#{state.id}) errored")

    %__MODULE__{state | status: :error}
  end

  defp handle_job_result(:error, %{status: :error} = state) do
    Logger.warn("Job (#{state.id}) is retrying")

    new_state = Map.update!(state, :retries, &(&1 + 1))

    if new_state.retries == state.max_retries do
      %__MODULE__{new_state | status: :fail}
    else
      new_state
    end
  end

  defp random_job_id() do
    :crypto.strong_rand_bytes(5) |> Base.url_encode64(padding: false)
  end

  defp via(key, value) do
    {:via, Registry, {Jobber.JobRegistry, key, value}}
  end
end
