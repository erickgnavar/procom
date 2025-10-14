defmodule ProcomWeb.ProductController do
  use ProcomWeb, :controller
  alias Procom.Products
  alias ProcomWeb.Schemas.{CompareResponse}
  alias OpenApiSpex.Schema

  use OpenApiSpex.ControllerSpecs

  tags ["products"]

  operation :compare,
    summary: "Compare products by SKU",
    description: """
    Retrieves multiple products by their SKUs for comparison.

    - SKUs are case-insensitive and will be normalized (trimmed and lowercased)
    - Duplicate SKUs are automatically removed
    - Non-existent SKUs will return null values
    - Empty or invalid SKUs are filtered out
    """,
    parameters: [
      sku: [
        in: :query,
        name: "sku[]",
        description:
          "Product SKU(s) to compare. Can be repeated multiple times for multiple products.",
        required: true,
        schema: %Schema{
          type: :array,
          items: %Schema{type: :string},
          minItems: 1,
          example: ["laptop-001", "mouse-005", "headphone-003"]
        },
        style: :form,
        explode: true
      ]
    ],
    responses: [
      ok: {"Success", "application/json", CompareResponse},
      bad_request:
        {"Bad Request - Invalid parameters", "application/json",
         %Schema{
           type: :object,
           properties: %{
             error: %Schema{type: :string, example: "Invalid SKU format"}
           }
         }}
    ]

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
