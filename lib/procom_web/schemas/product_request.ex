defmodule ProcomWeb.Schemas.ProductRequest do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ProductRequest",
    description: "Product creation request",
    type: :object,
    properties: %{
      sku: %Schema{
        type: :string,
        description: "Product SKU (will be normalized to lowercase)",
        example: "LAPTOP-001",
        pattern: "^[A-Za-z0-9-]+$"
      },
      name: %Schema{
        type: :string,
        description: "Product name",
        example: "MacBook Pro 16-inch",
        minLength: 1,
        maxLength: 255
      },
      description: %Schema{
        type: :string,
        description: "Product description",
        example: "Powerful laptop with M3 chip, 16GB RAM, and 512GB SSD",
        minLength: 1
      },
      image_url: %Schema{
        type: :string,
        format: :uri,
        description: "Product image URL",
        example: "https://example.com/images/macbook-pro-16.jpg",
        pattern: "^https?://.+"
      },
      price: %Schema{
        type: :integer,
        description: "Price in cents",
        example: 249_900,
        minimum: 1
      },
      rating: %Schema{
        type: :integer,
        description: "Product rating (1-5 stars)",
        example: 5,
        minimum: 1,
        maximum: 5
      }
    },
    required: [:sku, :name, :description, :image_url, :price, :rating],
    example: %{
      "sku" => "LAPTOP-001",
      "name" => "MacBook Pro 16-inch",
      "description" => "Powerful laptop with M3 chip, 16GB RAM, and 512GB SSD",
      "image_url" => "https://example.com/images/macbook-pro-16.jpg",
      "price" => 249_900,
      "rating" => 5
    }
  })
end
