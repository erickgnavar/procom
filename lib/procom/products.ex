defmodule Procom.Products do
  alias Procom.Products.Product
  alias Procom.Workers.Storage

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
