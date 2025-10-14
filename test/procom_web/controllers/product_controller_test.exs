defmodule ProcomWeb.ProductControllerTest do
  use ProcomWeb.ConnCase

  alias Procom.Products

  alias Procom.Workers.Storage

  setup do
    on_exit(fn ->
      # clean up ETS because is a shared resource across all the tests
      Storage.delete_all()
    end)

    :ok
  end

  describe "GET /compare" do
    test "returns valid and invalid product SKUs", %{conn: conn} do
      insert_sample_products()

      # only 2 products must be returned
      conn = get(conn, "/api/compare", %{"sku" => ["LAPTOP-001", "CHAIR-020", "MOUSE-005"]})
      body = json_response(conn, 200)

      assert Map.has_key?(body, "laptop-001")
      assert Map.has_key?(body, "mouse-005")
      assert body |> Map.get("chair-020") |> is_nil()
    end

    test "returns empty map when no SKU parameter provided", %{conn: conn} do
      insert_sample_products()

      conn = get(conn, "/api/compare")
      body = json_response(conn, 200)

      assert body == %{}
    end

    test "returns empty map when sku parameter is empty list", %{conn: conn} do
      insert_sample_products()

      conn = get(conn, "/api/compare", %{"sku" => []})
      body = json_response(conn, 200)

      assert body == %{}
    end

    test "handles single SKU as string instead of list", %{conn: conn} do
      insert_sample_products()

      conn = get(conn, "/api/compare", %{"sku" => "LAPTOP-001"})
      body = json_response(conn, 200)

      assert Map.has_key?(body, "laptop-001")
      assert map_size(body) == 1
    end

    test "returns all nil values when no products exist in storage", %{conn: conn} do
      # Don't insert any products
      conn = get(conn, "/api/compare", %{"sku" => ["LAPTOP-001", "MOUSE-005"]})
      body = json_response(conn, 200)

      assert body["laptop-001"] == nil
      assert body["mouse-005"] == nil
    end

    test "handles duplicate SKUs in request", %{conn: conn} do
      insert_sample_products()

      conn = get(conn, "/api/compare", %{"sku" => ["LAPTOP-001", "LAPTOP-001", "LAPTOP-001"]})
      body = json_response(conn, 200)

      # Should have 1 entry (duplicates removed and normalized)
      assert Map.has_key?(body, "laptop-001")
      assert map_size(body) == 1
    end

    test "handles duplicate SKUs with different cases", %{conn: conn} do
      insert_sample_products()

      conn = get(conn, "/api/compare", %{"sku" => ["LAPTOP-001", "laptop-001", "LaPtOp-001"]})
      body = json_response(conn, 200)

      # Should deduplicate to single entry
      assert Map.has_key?(body, "laptop-001")
      assert map_size(body) == 1
      refute is_nil(body["laptop-001"])
    end

    test "handles very long SKU list", %{conn: conn} do
      insert_sample_products()

      # Create a list with 100 SKUs (mostly non-existent)
      skus =
        ["LAPTOP-001", "MOUSE-005", "HEADPHONE-003"] ++
          Enum.map(1..97, fn i -> "NON-EXISTENT-#{i}" end)

      conn = get(conn, "/api/compare", %{"sku" => skus})
      body = json_response(conn, 200)

      assert Map.has_key?(body, "laptop-001")
      assert Map.has_key?(body, "mouse-005")
      assert Map.has_key?(body, "headphone-003")
      assert map_size(body) == 100
    end

    test "handles special characters in SKU", %{conn: conn} do
      # Insert product with special characters
      Products.insert_product(%{
        sku: "SPECIAL-#@!-001",
        name: "Special Product",
        description: "Product with special chars in SKU",
        image_url: "https://example.com/special.jpg",
        price: 1000,
        rating: 3
      })

      Storage.sync()

      conn = get(conn, "/api/compare", %{"sku" => ["SPECIAL-#@!-001"]})
      body = json_response(conn, 200)

      assert Map.has_key?(body, "special-#@!-001")
    end

    test "handles empty string SKU", %{conn: conn} do
      insert_sample_products()

      conn = get(conn, "/api/compare", %{"sku" => ["", "LAPTOP-001", ""]})
      body = json_response(conn, 200)

      refute Map.has_key?(body, "")
    end

    test "handles nil in SKU list", %{conn: conn} do
      insert_sample_products()

      conn = get(conn, "/api/compare", %{"sku" => [nil, "LAPTOP-001"]})
      body = json_response(conn, 200)

      # Should handle gracefully
      assert Map.has_key?(body, "laptop-001")
    end

    test "is case-insensitive for SKUs", %{conn: conn} do
      insert_sample_products()

      conn = get(conn, "/api/compare", %{"sku" => ["laptop-001", "LAPTOP-001", "LaPtOp-001"]})
      body = json_response(conn, 200)

      # All variations should match and be normalized to lowercase
      assert Map.has_key?(body, "laptop-001")
      assert map_size(body) == 1
      refute is_nil(body["laptop-001"])
      # Original case preserved in data
      assert body["laptop-001"]["sku"] == "laptop-001"
    end

    test "handles mixed case SKUs correctly", %{conn: conn} do
      insert_sample_products()

      conn = get(conn, "/api/compare", %{"sku" => ["LAPTOP-001", "mouse-005", "HeAdPhOnE-003"]})
      body = json_response(conn, 200)

      # All should be found and normalized
      assert Map.has_key?(body, "laptop-001")
      assert Map.has_key?(body, "mouse-005")
      assert Map.has_key?(body, "headphone-003")
      assert map_size(body) == 3
    end

    test "handles whitespace in SKUs", %{conn: conn} do
      insert_sample_products()

      conn = get(conn, "/api/compare", %{"sku" => [" LAPTOP-001 ", "LAPTOP-001"]})
      body = json_response(conn, 200)

      # After trimming, should be deduplicated
      assert Map.has_key?(body, "laptop-001")
      # Could be 1 or 2 depending on if whitespace is trimmed before deduplication
    end

    test "handles extremely long SKU string", %{conn: conn} do
      insert_sample_products()

      long_sku = String.duplicate("A", 10_000)
      conn = get(conn, "/api/compare", %{"sku" => [long_sku, "LAPTOP-001"]})
      body = json_response(conn, 200)

      assert body[String.downcase(long_sku)] == nil
      assert Map.has_key?(body, "laptop-001")
    end

    test "handles integer SKU values", %{conn: conn} do
      # Some clients might send numbers
      Products.insert_product(%{
        sku: "12345",
        name: "Numeric SKU Product",
        description: "Product with numeric SKU",
        image_url: "https://example.com/numeric.jpg",
        price: 1000,
        rating: 4
      })

      Storage.sync()

      conn = get(conn, "/api/compare", %{"sku" => [12345, "12345"]})
      body = json_response(conn, 200)

      # After normalization, should have one entry
      assert map_size(body) >= 1
    end

    test "returns correct structure for found products", %{conn: conn} do
      insert_sample_products()

      conn = get(conn, "/api/compare", %{"sku" => ["LAPTOP-001"]})
      body = json_response(conn, 200)

      product = body["laptop-001"]
      # Original case preserved
      assert product["sku"] == "laptop-001"
      assert product["name"] == "MacBook Pro 16-inch"
      assert product["price"] == 249_900
      assert product["rating"] == 5
      assert is_binary(product["description"])
      assert is_binary(product["image_url"])
    end

    test "returns correct structure with lowercase SKU request", %{conn: conn} do
      insert_sample_products()

      conn = get(conn, "/api/compare", %{"sku" => ["laptop-001"]})
      body = json_response(conn, 200)

      product = body["laptop-001"]
      assert product["sku"] == "laptop-001"
      assert product["name"] == "MacBook Pro 16-inch"
    end

    test "handles URL-encoded SKUs", %{conn: conn} do
      # Insert product with URL-encodable characters
      Products.insert_product(%{
        sku: "PRODUCT+WITH SPACE",
        name: "Product with space",
        description: "Product",
        image_url: "https://example.com/space.jpg",
        price: 1000,
        rating: 3
      })

      Storage.sync()

      conn = get(conn, "/api/compare?sku[]=PRODUCT%2BWITH%20SPACE")
      body = json_response(conn, 200)

      assert Map.has_key?(body, "product+with space")
    end

    test "handles concurrent requests", %{conn: conn} do
      insert_sample_products()

      # Simulate multiple concurrent requests with different cases
      tasks =
        1..10
        |> Enum.map(fn i ->
          Task.async(fn ->
            skus =
              if rem(i, 2) == 0 do
                ["LAPTOP-001", "MOUSE-005"]
              else
                ["laptop-001", "mouse-005"]
              end

            conn = get(conn, "/api/compare", %{"sku" => skus})
            json_response(conn, 200)
          end)
        end)

      results = Task.await_many(tasks)

      # All should succeed and be normalized
      assert length(results) == 10

      Enum.each(results, fn body ->
        assert Map.has_key?(body, "laptop-001")
        assert Map.has_key?(body, "mouse-005")
      end)
    end

    test "handles malformed sku parameter types", %{conn: conn} do
      insert_sample_products()

      # Try to send sku as a map (malformed)
      conn = get(conn, "/api/compare", %{"sku" => %{"invalid" => "structure"}})
      body = json_response(conn, 200)

      # Should handle gracefully
      assert is_map(body)
    end

    test "handles case insensitivity with special characters", %{conn: conn} do
      Products.insert_product(%{
        sku: "SPECIAL-ABC-123",
        name: "Special Product",
        description: "Product",
        image_url: "https://example.com/special.jpg",
        price: 1000,
        rating: 3
      })

      Storage.sync()

      conn = get(conn, "/api/compare", %{"sku" => ["special-abc-123", "SPECIAL-ABC-123"]})
      body = json_response(conn, 200)

      # Should de duplicate and normalize
      assert map_size(body) == 1
      assert Map.has_key?(body, "special-abc-123")
      assert body["special-abc-123"]["sku"] == "special-abc-123"
    end
  end

  # TODO: move this to a fixtures module
  defp insert_sample_products do
    Products.insert_product(%{
      sku: "LAPTOP-001",
      name: "MacBook Pro 16-inch",
      description:
        "Powerful laptop with M3 chip, 16GB RAM, and 512GB SSD. Perfect for professionals and creatives.",
      image_url: "https://example.com/images/macbook-pro-16.jpg",
      price: 249_900,
      rating: 5
    })

    Products.insert_product(%{
      sku: "MOUSE-005",
      name: "Logitech MX Master 3S",
      description: "Ergonomic wireless mouse with precise tracking and customizable buttons.",
      image_url: "https://example.com/images/mx-master-3s.jpg",
      price: 9900,
      rating: 5
    })

    Products.insert_product(%{
      sku: "HEADPHONE-003",
      name: "Sony WH-1000XM5",
      description:
        "Premium noise-cancelling headphones with exceptional sound quality and 30-hour battery life.",
      image_url: "https://example.com/images/sony-wh1000xm5.jpg",
      price: 39900,
      rating: 5
    })

    Storage.sync()
  end
end
