defmodule Procom.Products.Product do
  @moduledoc """
  Representation of a product

  sku: unique identifier along all the system, must be lower case
  name: free text
  image_url: valid URL
  description: free text
  price: integer value in cents
  rating: integer value in cents
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :sku, :string
    field :name, :string
    field :description, :string
    field :image_url, :string
    field :price, :integer
    field :rating, :integer
    # TODO: add custom attributes
  end

  @all_fields [:sku, :name, :description, :image_url, :price, :rating]

  @doc false
  def changeset(link, attrs) do
    link
    |> cast(attrs, @all_fields)
    |> validate_required(@all_fields)
    |> validate_url(:image_url)
    # TODO: a price can have price 0?
    |> validate_number(:price, greater_than: 0)
    # we assume a rating system of 5 stars
    |> validate_number(:rating, greater_than: 0)
    |> validate_number(:rating, less_than: 6)
  end

  def validate_url(changeset, field) do
    validate_change(changeset, field, fn _, url ->
      case URI.parse(url) do
        %URI{scheme: scheme, host: host} when scheme in ["http", "https"] and not is_nil(host) ->
          []

        _ ->
          # TODO: i18n support for error message
          [{field, "must be a valid HTTP or HTTPS URL"}]
      end
    end)
  end
end
