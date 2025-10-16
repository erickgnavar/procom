defmodule Procom.Workers.Store do
  @moduledoc """
  Save all the content of products ETS table into a JSON file
  """
  use GenServer

  @interval :timer.minutes(5)

  require Logger

  alias Procom.Workers.Storage

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, :no_state, {:continue, :schedule}}
  end

  @impl true
  def handle_continue(:schedule, state) do
    restore()
    {:noreply, state}
  end

  @impl true
  def handle_info(:backup, state) do
    backup()
    schedule()
    {:noreply, state}
  end

  defp restore do
    path = backup_path()
    # restore call must be done from Storage module because only that
    # process can write to ETS table
    case Storage.restore(path) do
      :ok ->
        Logger.info("Products ETS table restored from filesystem: #{path}")

      {:error, reason} ->
        Logger.info("There was an error while restoring: #{inspect(reason)}")
    end

    schedule()
  end

  defp schedule do
    Process.send_after(self(), :backup, @interval)
  end

  defp backup do
    # we use erlang to binary system because is faster than using
    # plain text like CSV or JSON, also we avoid serialization process
    # because all the data is saved and restored in binary format
    path = backup_path()
    Storage.backup(path)

    Logger.info("Products ETS table dumped into filesystem: #{path}")
  end

  defp backup_path do
    # this will generate a path inside application root directory
    Application.app_dir(:procom, "backup.ets")
  end
end
