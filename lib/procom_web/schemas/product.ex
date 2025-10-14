defmodule ProcomWeb.Schemas.Product do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Product",
    description: "A product in the catalog",
    type: :object,
    properties: %{
      sku: %Schema{
        type: :string,
        description: "Product SKU (normalized to lowercase)",
        example: "laptop-001"
      },
      name: %Schema{type: :string, description: "Product name", example: "MacBook Pro 16-inch"},
      description: %Schema{type: :string, description: "Product description"},
      image_url: %Schema{type: :string, format: :uri, description: "Product image URL"},
      price: %Schema{type: :integer, description: "Price in cents", example: 249_900},
      rating: %Schema{
        type: :integer,
        minimum: 1,
        maximum: 5,
        description: "Product rating (1-5 stars)",
        example: 5
      }
    },
    required: [:sku, :name, :description, :image_url, :price, :rating],
    example: %{
      "sku" => "laptop-001",
      "name" => "MacBook Pro 16-inch",
      "description" => "Powerful laptop with M3 chip, 16GB RAM, and 512GB SSD",
      "image_url" => "https://example.com/images/macbook-pro-16.jpg",
      "price" => 249_900,
      "rating" => 5
    }
  })
end
