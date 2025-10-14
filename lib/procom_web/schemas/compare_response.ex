defmodule ProcomWeb.Schemas.CompareResponse do
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias ProcomWeb.Schemas.Product

  OpenApiSpex.schema(%{
    title: "CompareResponse",
    description: "Response containing requested products by SKU",
    type: :object,
    additionalProperties: %Schema{
      oneOf: [
        Product,
        %Schema{type: :null}
      ]
    },
    example: %{
      "laptop-001" => %{
        "sku" => "laptop-001",
        "name" => "MacBook Pro 16-inch",
        "description" => "Powerful laptop",
        "image_url" => "https://example.com/images/macbook.jpg",
        "price" => 249_900,
        "rating" => 5
      },
      "mouse-005" => %{
        "sku" => "mouse-005",
        "name" => "Logitech MX Master 3S",
        "description" => "Ergonomic mouse",
        "image_url" => "https://example.com/images/mouse.jpg",
        "price" => 9900,
        "rating" => 5
      },
      "non-existent-sku" => nil
    }
  })
end
