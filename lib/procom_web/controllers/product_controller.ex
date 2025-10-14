defmodule ProcomWeb.ProductController do
  use ProcomWeb, :controller
  alias Procom.Products

  def compare(conn, params) do
    result = search_products(params)

    # TODO: check if we need to add a rate limit at this level, in
    # case there is not other layer on top of this service like an api
    # gateway
    json(conn, result)
  end

  @spec search_products(map) :: map
  defp search_products(params) do
    params
    |> Map.get("sku")
    |> List.wrap()
    |> Enum.filter(&(String.Chars.impl_for(&1) != nil))
    |> Enum.map(&to_string/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.downcase/1)
    |> Enum.uniq()
    |> Enum.map(fn normalized_sku ->
      normalized_sku
      |> Products.get_product()
      |> case do
        {:ok, product} -> {normalized_sku, product}
        {:error, _reason} -> {normalized_sku, nil}
      end
    end)
    |> Enum.into(%{})
  end
end
