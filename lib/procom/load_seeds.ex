defmodule Mix.Tasks.LoadSeeds do
  @moduledoc """
  Helper function to load data from JSON file

  JSON file must have the following form:

  [
    {
      "sku": "LAPTOP-001",
      "name": "MacBook Pro 16-inch",
      "description": "Powerful laptop with M3 chip, 16GB RAM, and 512GB SSD. Perfect for professionals and creatives.",
      "image_url": "https://example.com/images/macbook-pro-16.jpg",
      "price": 249900,
      "rating": 5
    }
  ]
  """

  use Mix.Task

  alias Procom.Products

  def run([sample_path]) do
    Application.ensure_all_started(:procom)

    File.open(sample_path, [:read, :utf8], fn file ->
      file
      |> IO.read(:eof)
      |> Jason.decode!()
      |> Enum.map(&Products.insert_product/1)
    end)
  end

  def run(_), do: IO.puts("A JSON path is required")
end
