defmodule MvpMatchCodeChallenge.ProductsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MvpMatchCodeChallenge.Products` context.
  """

  def valid_product_attributes(attrs \\ %{}) do
    user = MvpMatchCodeChallenge.AccountsFixtures.user_fixture(%{role: :seller})

    Enum.into(attrs, %{
      amount_available: 42,
      cost: "120.5",
      product_name: "some product_name#{System.unique_integer()}",
      seller_id: user.id
    })
  end

  @doc """
  Generate a product.
  """
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> valid_product_attributes()
      |> MvpMatchCodeChallenge.Products.create_product()

    product
  end
end
