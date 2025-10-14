defmodule Procom.Products do
  alias Procom.Products.Product
  alias Procom.Workers.Storage

  @spec get_product(sku :: String.t()) :: {:ok, Product.t()} | {:error, reason :: String.t()}
  def get_product(sku) do
    case Storage.get(sku) do
      {:error, :not_found} -> {:error, :not_found}
      {_key, product} -> {:ok, product}
    end
  end

  # TODO: maybe change the result type, instead of a list of tuples
  # use a list of structs
  # By now we just define this to have a unique point of interaction
  # with products without passing through storage module
  defdelegate list_all, to: Storage

  @spec insert_product(map) :: {:ok, Product.t()} | {:error, Ecto.Changeset.t()}
  def insert_product(attrs) do
    %Product{}
    |> Product.changeset(attrs)
    |> case do
      # changes map has the already sanitized data so we can create a
      # product struct with its content
      %{valid?: true, changes: changes} -> {:ok, struct(Product, changes)}
      # TODO: format errors
      %{errors: errors} -> {:error, errors}
    end
    |> insert_into_storage()
  end

  defp insert_into_storage({:error, errors}), do: {:error, errors}

  defp insert_into_storage({:ok, data}) do
    :ok = Storage.insert(data.sku, data)
    {:ok, data}
  end
end
