defmodule Procom.ProductsTest do
  use ExUnit.Case

  alias Procom.Products
  alias Procom.Workers.Storage

  setup do
    on_exit(fn ->
      # clean up ETS because is a shared resource across all the tests
      Storage.delete_all()
    end)

    :ok
  end

  test "Insert product with valid attrs" do
    attrs = %{
      sku: "000001",
      name: "iPhone",
      description: "lorem ipsum",
      image_url: "https://image.com/hello.png",
      price: 10,
      rating: 5
    }

    assert {:error, :not_found} = Storage.get(attrs.sku)
    assert {:ok, %{sku: product_sku}} = Products.insert_product(attrs)
    # force sync operation to avoid race condition
    Storage.sync()
    assert {:ok, %{sku: ^product_sku}} = Storage.get(attrs.sku)
  end

  test "Duplicates are not allowed, in case of duplicate we override data" do
    attrs = %{
      sku: "000001",
      name: "iPhone",
      description: "lorem ipsum",
      image_url: "https://image.com/hello.png",
      price: 10,
      rating: 5
    }

    updated_attrs = Map.put(attrs, :name, "macbook")

    assert {:error, :not_found} = Storage.get(attrs.sku)
    assert {:ok, %{sku: product_sku}} = Products.insert_product(attrs)

    # force sync operation to avoid race condition
    Storage.sync()

    assert {:ok, %{sku: ^product_sku}} = Storage.get(attrs.sku)

    assert [_] = Storage.list_all()
    # try to insert again
    assert {:ok, _product} = Products.insert_product(updated_attrs)

    # force sync again
    Storage.sync()

    assert [{_key, product}] = Storage.list_all()
    assert product.name == "macbook"
  end

  test "Cannot insert invalid data to products storage" do
    attrs = %{price: 0, name: "product name"}
    assert {:error, errors} = Products.insert_product(attrs)
    assert Keyword.has_key?(errors, :price)
    assert Keyword.has_key?(errors, :sku)
  end
end
