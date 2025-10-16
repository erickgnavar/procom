defmodule ProcomWeb.ProductController do
  use ProcomWeb, :controller
  alias Procom.Products
  alias ProcomWeb.Schemas.{CompareResponse, ProductRequest, Product, ErrorResponse}
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

  operation :load,
    summary: "Load a single product",
    description: """
    Creates and loads a new product into the storage system.

    In case a product with the same SKU already exist it will be replaced

    All fields are required and will be validated:
    - SKU must be unique and will be normalized (lowercase, trimmed)
    - Price must be greater than 0
    - Rating must be between 1 and 5
    - Image URL must be a valid URL format
    """,
    request_body: {
      "Product data",
      "application/json",
      ProductRequest,
      required: true,
      example: %{
        sku: "LAPTOP-001",
        name: "MacBook Pro 16-inch",
        description: "Powerful laptop with M3 chip, 16GB RAM, and 512GB SSD",
        image_url: "https://example.com/images/macbook-pro-16.jpg",
        price: 249_900,
        rating: 5
      }
    },
    responses: [
      ok: {
        "Product loaded successfully",
        "application/json",
        Product,
        example: %{
          sku: "laptop-001",
          name: "MacBook Pro 16-inch",
          description: "Powerful laptop with M3 chip, 16GB RAM, and 512GB SSD",
          image_url: "https://example.com/images/macbook-pro-16.jpg",
          price: 249_900,
          rating: 5
        }
      },
      bad_request: {
        "Validation errors",
        "application/json",
        ErrorResponse,
        example: %{
          sku: ["can't be blank"],
          price: ["must be greater than 0"],
          rating: ["must be less than 6"]
        }
      }
    ]

  def load(conn, params) do
    case Products.insert_product(params) do
      {:ok, product} ->
        json(conn, product)

      {:error, errors} ->
        response = format_errors(errors)

        conn
        |> put_status(400)
        |> json(response)
    end
  end

  defp format_errors(errors) do
    changeset = %Ecto.Changeset{errors: errors}

    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
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
