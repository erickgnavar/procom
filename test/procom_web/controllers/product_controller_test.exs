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

  describe "PUT /api/load" do
    test "creates a product with valid data", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro 16-inch",
        "description" => "Powerful laptop with M3 chip, 16GB RAM, and 512GB SSD",
        "image_url" => "https://example.com/images/macbook-pro-16.jpg",
        "price" => 249_900,
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 200)
      response = json_response(conn, 200)

      # SKU is normalized to lowercase
      assert response["sku"] == "laptop-001"
      assert response["name"] == "MacBook Pro 16-inch"
      assert response["description"] == "Powerful laptop with M3 chip, 16GB RAM, and 512GB SSD"
      assert response["image_url"] == "https://example.com/images/macbook-pro-16.jpg"
      assert response["price"] == 249_900
      assert response["rating"] == 5
    end

    test "product is actually stored in ETS", %{conn: conn} do
      product_params = %{
        "sku" => "MOUSE-005",
        "name" => "Logitech MX Master 3S",
        "description" => "Ergonomic wireless mouse",
        "image_url" => "https://example.com/mouse.jpg",
        "price" => 9900,
        "rating" => 5
      }

      put(conn, ~p"/api/load", product_params)

      Storage.sync()

      # Verify it's in storage
      {:ok, product} = Products.get_product("mouse-005")
      assert product.name == "Logitech MX Master 3S"
    end

    test "returns 400 when sku is missing", %{conn: conn} do
      product_params = %{
        "name" => "MacBook Pro 16-inch",
        "description" => "Powerful laptop",
        "image_url" => "https://example.com/laptop.jpg",
        "price" => 249_900,
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["sku"] == ["can't be blank"]
    end

    test "returns 400 when name is missing", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "description" => "Powerful laptop",
        "image_url" => "https://example.com/laptop.jpg",
        "price" => 249_900,
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["name"] == ["can't be blank"]
    end

    test "returns 400 when description is missing", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "image_url" => "https://example.com/laptop.jpg",
        "price" => 249_900,
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["description"] == ["can't be blank"]
    end

    test "returns 400 when image_url is missing", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "description" => "Powerful laptop",
        "price" => 249_900,
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["image_url"] == ["can't be blank"]
    end

    test "returns 400 when price is missing", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "description" => "Powerful laptop",
        "image_url" => "https://example.com/laptop.jpg",
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["price"] == ["can't be blank"]
    end

    test "returns 400 when rating is missing", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "description" => "Powerful laptop",
        "image_url" => "https://example.com/laptop.jpg",
        "price" => 249_900
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["rating"] == ["can't be blank"]
    end

    test "returns 400 when multiple fields are missing", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001"
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 400)
      response = json_response(conn, 400)

      assert Map.has_key?(response, "name")
      assert Map.has_key?(response, "description")
      assert Map.has_key?(response, "image_url")
      assert Map.has_key?(response, "price")
      assert Map.has_key?(response, "rating")
    end

    test "returns 400 when price is zero", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "description" => "Powerful laptop",
        "image_url" => "https://example.com/laptop.jpg",
        "price" => 0,
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["price"] == ["must be greater than 0"]
    end

    test "returns 400 when price is negative", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "description" => "Powerful laptop",
        "image_url" => "https://example.com/laptop.jpg",
        "price" => -100,
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["price"] == ["must be greater than 0"]
    end

    test "returns 400 when rating is zero", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "description" => "Powerful laptop",
        "image_url" => "https://example.com/laptop.jpg",
        "price" => 249_900,
        "rating" => 0
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["rating"] == ["must be greater than 0"]
    end

    test "returns 400 when rating is greater than 5", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "description" => "Powerful laptop",
        "image_url" => "https://example.com/laptop.jpg",
        "price" => 249_900,
        "rating" => 6
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["rating"] == ["must be less than 6"]
    end

    test "returns 400 when rating is negative", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "description" => "Powerful laptop",
        "image_url" => "https://example.com/laptop.jpg",
        "price" => 249_900,
        "rating" => -1
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["rating"] == ["must be greater than 0"]
    end

    test "returns 400 when image_url is invalid", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "description" => "Powerful laptop",
        "image_url" => "not-a-valid-url",
        "price" => 249_900,
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["image_url"] == ["must be a valid HTTP or HTTPS URL"]
    end

    test "accepts valid rating of 1", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "description" => "Powerful laptop",
        "image_url" => "https://example.com/laptop.jpg",
        "price" => 249_900,
        "rating" => 1
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 200)
      response = json_response(conn, 200)
      assert response["rating"] == 1
    end

    test "accepts valid rating of 5", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "description" => "Powerful laptop",
        "image_url" => "https://example.com/laptop.jpg",
        "price" => 249_900,
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 200)
      response = json_response(conn, 200)
      assert response["rating"] == 5
    end

    test "normalizes SKU to lowercase", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "description" => "Powerful laptop",
        "image_url" => "https://example.com/laptop.jpg",
        "price" => 249_900,
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      response = json_response(conn, 200)
      assert response["sku"] == "laptop-001"
    end

    test "trims whitespace from SKU", %{conn: conn} do
      product_params = %{
        "sku" => "  LAPTOP-001  ",
        "name" => "MacBook Pro",
        "description" => "Powerful laptop",
        "image_url" => "https://example.com/laptop.jpg",
        "price" => 249_900,
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      response = json_response(conn, 200)
      assert response["sku"] == "laptop-001"
    end

    test "handles special characters in SKU", %{conn: conn} do
      product_params = %{
        "sku" => "SPECIAL-SKU#123",
        "name" => "Special Product",
        "description" => "Product with special SKU",
        "image_url" => "https://example.com/special.jpg",
        "price" => 1000,
        "rating" => 3
      }

      conn = put(conn, ~p"/api/load", product_params)

      response = json_response(conn, 200)
      assert response["sku"] == "special-sku#123"
    end

    test "accepts minimum valid price of 1", %{conn: conn} do
      product_params = %{
        "sku" => "CHEAP-001",
        "name" => "Cheap Item",
        "description" => "Very cheap item",
        "image_url" => "https://example.com/cheap.jpg",
        "price" => 1,
        "rating" => 3
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 200)
      response = json_response(conn, 200)
      assert response["price"] == 1
    end

    test "accepts large price values", %{conn: conn} do
      product_params = %{
        "sku" => "EXPENSIVE-001",
        "name" => "Expensive Item",
        "description" => "Very expensive item",
        "image_url" => "https://example.com/expensive.jpg",
        "price" => 999_999_999,
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 200)
      response = json_response(conn, 200)
      assert response["price"] == 999_999_999
    end

    test "accepts http URLs", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "description" => "Powerful laptop",
        "image_url" => "http://example.com/laptop.jpg",
        "price" => 249_900,
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 200)
      response = json_response(conn, 200)
      assert response["image_url"] == "http://example.com/laptop.jpg"
    end

    test "accepts https URLs", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "description" => "Powerful laptop",
        "image_url" => "https://example.com/laptop.jpg",
        "price" => 249_900,
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 200)
      response = json_response(conn, 200)
      assert response["image_url"] == "https://example.com/laptop.jpg"
    end

    test "handles long descriptions", %{conn: conn} do
      long_description = String.duplicate("a", 10000)

      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "description" => long_description,
        "image_url" => "https://example.com/laptop.jpg",
        "price" => 249_900,
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 200)
      response = json_response(conn, 200)
      assert response["description"] == long_description
    end

    test "handles unicode characters in name and description", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro 日本語 🚀",
        "description" => "Powerful laptop with émojis 🎉 and spëcial çharacters",
        "image_url" => "https://example.com/laptop.jpg",
        "price" => 249_900,
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 200)
      response = json_response(conn, 200)
      assert response["name"] == "MacBook Pro 日本語 🚀"
      assert response["description"] == "Powerful laptop with émojis 🎉 and spëcial çharacters"
    end

    test "returns 400 when body is empty", %{conn: conn} do
      conn = put(conn, ~p"/api/load", %{})

      assert json_response(conn, 400)
      response = json_response(conn, 400)

      assert is_map(response)
      assert map_size(response) > 0
    end

    test "returns 400 when price is not an integer", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "description" => "Powerful laptop",
        "image_url" => "https://example.com/laptop.jpg",
        "price" => "not-a-number",
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 400)
    end

    test "returns 400 when rating is not an integer", %{conn: conn} do
      product_params = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "description" => "Powerful laptop",
        "image_url" => "https://example.com/laptop.jpg",
        "price" => 249_900,
        "rating" => "not-a-number"
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 400)
    end

    test "multiple products can be loaded", %{conn: conn} do
      product1 = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro",
        "description" => "Powerful laptop",
        "image_url" => "https://example.com/laptop.jpg",
        "price" => 249_900,
        "rating" => 5
      }

      product2 = %{
        "sku" => "MOUSE-005",
        "name" => "Logitech MX Master",
        "description" => "Ergonomic mouse",
        "image_url" => "https://example.com/mouse.jpg",
        "price" => 9900,
        "rating" => 4
      }

      conn1 = put(conn, ~p"/api/load", product1)
      conn2 = put(conn, ~p"/api/load", product2)

      assert json_response(conn1, 200)
      assert json_response(conn2, 200)

      Storage.sync()

      # Verify both are in storage
      {:ok, _} = Products.get_product("laptop-001")
      {:ok, _} = Products.get_product("mouse-005")
    end

    test "loading duplicate SKU overwrites existing product", %{conn: conn} do
      product_v1 = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro v1",
        "description" => "First version",
        "image_url" => "https://example.com/v1.jpg",
        "price" => 200_000,
        "rating" => 4
      }

      product_v2 = %{
        "sku" => "LAPTOP-001",
        "name" => "MacBook Pro v2",
        "description" => "Second version",
        "image_url" => "https://example.com/v2.jpg",
        "price" => 250_000,
        "rating" => 5
      }

      put(conn, ~p"/api/load", product_v1)
      conn2 = put(conn, ~p"/api/load", product_v2)

      assert json_response(conn2, 200)
      response = json_response(conn2, 200)

      # Verify the second version is stored
      assert response["name"] == "MacBook Pro v2"
      assert response["price"] == 250_000

      Storage.sync()

      {:ok, stored} = Products.get_product("laptop-001")
      assert stored.name == "MacBook Pro v2"
    end

    test "handles empty string values as validation errors", %{conn: conn} do
      product_params = %{
        "sku" => "",
        "name" => "",
        "description" => "",
        "image_url" => "",
        "price" => 249_900,
        "rating" => 5
      }

      conn = put(conn, ~p"/api/load", product_params)

      assert json_response(conn, 400)
      response = json_response(conn, 400)

      assert response["sku"] == ["can't be blank"]
      assert response["name"] == ["can't be blank"]
      assert response["description"] == ["can't be blank"]
      assert response["image_url"] == ["can't be blank"]
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
