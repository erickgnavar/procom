defmodule Procom.Workers.Storage do
  use GenServer

  @table_name :products

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def insert(product_sku, product_data) do
    GenServer.cast(__MODULE__, {:insert_product, sanitize_key(product_sku), product_data})
  end

  def get(key) do
    # table has public read access so we can read directly from here
    key = sanitize_key(key)

    case :ets.lookup(@table_name, key) do
      [{^key, product}] -> {:ok, product}
      [] -> {:error, :not_found}
    end
  end

  def list_all do
    :ets.tab2list(@table_name)
  end

  def backup(path) do
    GenServer.cast(__MODULE__, {:backup, path})
  end

  def restore(path) do
    GenServer.call(__MODULE__, {:restore, path})
  end

  def delete(product_sku) do
    :ets.delete(@table_name, product_sku)
  end

  @doc """
  Only meant to be used in tests as a clean up action
  """
  def delete_all do
    GenServer.call(__MODULE__, :delete_all)
  end

  @doc """
  Force to flush all the messages before doing
  something else

  This is meant to be used only for testing purposes
  """
  def sync do
    GenServer.call(__MODULE__, :sync)
  end

  @impl true
  def init(_opts) do
    table =
      :ets.new(@table_name, [
        # each key must be unique
        :set,
        # everyone can read but only owner process can write
        :protected,
        :named_table,
        read_concurrency: true,
        write_concurrency: true
      ])

    {:ok, %{table: table}}
  end

  @impl true
  def handle_call(:sync, _from, state) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:delete_all, _from, state) do
    :ets.delete_all_objects(@table_name)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:restore, path}, _from, state) do
    return_value =
      case :ets.file2tab(String.to_charlist(path), table: @table_name) do
        {:ok, _table_ref} -> :ok
        {:error, reason} -> {:error, reason}
      end

    {:reply, return_value, state}
  end

  @impl true
  def handle_cast({:backup, path}, state) do
    case :ets.tab2file(@table_name, String.to_charlist(path)) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:insert_product, key, product}, state) do
    :ets.insert(@table_name, {sanitize_key(key), product})
    {:noreply, state}
  end

  defp sanitize_key(value) when is_binary(value), do: value |> String.trim() |> String.downcase()
  defp sanitize_key(value), do: value |> to_string() |> sanitize_key()
end
