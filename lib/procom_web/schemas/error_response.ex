defmodule ProcomWeb.Schemas.ErrorResponse do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ErrorResponse",
    description: "Validation error response",
    type: :object,
    additionalProperties: %Schema{
      type: :array,
      items: %Schema{type: :string}
    },
    example: %{
      "sku" => ["can't be blank"],
      "price" => ["must be greater than 0"],
      "rating" => ["must be less than or equal to 5", "must be greater than or equal to 1"],
      "image_url" => ["is invalid"]
    }
  })
end
