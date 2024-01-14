defmodule MvpMatchCodeChallenge.ProductsTest do
  use MvpMatchCodeChallenge.DataCase, async: true

  alias MvpMatchCodeChallenge.Products
  alias MvpMatchCodeChallenge.Products.Product
  alias MvpMatchCodeChallenge.AccountsFixtures

  import MvpMatchCodeChallenge.ProductsFixtures

  @invalid_attrs %{amount_available: nil, cost: nil, product_name: nil}

  describe "list_products/0" do
    test "list_products/0 returns all products" do
      product = product_fixture()
      assert Products.list_products() == [product]
    end
  end

  describe "get_product!/1" do
    test "returns the product with given id" do
      product = product_fixture()
      assert Products.get_product!(product.id) == product
    end
  end

  describe "get_product_by_seller_id/2" do
    test "returns the product with given id and seller_id" do
      product_seller = AccountsFixtures.user_fixture(%{role: :seller})
      product = product_fixture(%{seller_id: product_seller.id})
      assert Products.get_product_by_seller_id(product.id, product_seller.id) == product
    end

    test "returns nil if user is not the product seller" do
      random_seller = AccountsFixtures.user_fixture(%{role: :seller})
      product = product_fixture()
      assert Products.get_product_by_seller_id(product.id, random_seller.id) == nil
    end

    test "returns nil if product does not exist" do
      product_seller = AccountsFixtures.user_fixture(%{role: :seller})
      assert Products.get_product_by_seller_id(-1, product_seller.id) == nil
    end

    test "returns nil if user does not exist" do
      product = product_fixture()
      assert Products.get_product_by_seller_id(product.id, -1) == nil
    end
  end

  describe "create_product/1" do
    test "valid data creates a product" do
      seller_id = AccountsFixtures.user_fixture().id

      valid_attrs = %{
        amount_available: 42,
        cost: "120.5",
        product_name: "some product_name",
        seller_id: seller_id
      }

      assert {:ok, %Product{} = product} = Products.create_product(valid_attrs)
      assert product.amount_available == 42
      assert product.cost == Decimal.new("120.5")
      assert product.product_name == "some product_name"
    end

    test "invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Products.create_product(@invalid_attrs)
    end

    test "validates required fields" do
      {:error, changeset} = Products.create_product(%{})

      assert %{
               amount_available: ["can't be blank"],
               cost: ["can't be blank"],
               product_name: ["can't be blank"],
               seller_id: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates seller_id" do
      product = valid_product_attributes(%{seller_id: "foo"})
      {:error, changeset} = Products.create_product(product)
      assert %{seller_id: ["invalid user id", "is invalid"]} = errors_on(changeset)

      product = valid_product_attributes(%{seller_id: -1})
      {:error, changeset} = Products.create_product(product)
      assert %{seller_id: ["does not exist"]} = errors_on(changeset)

      buyer_user = AccountsFixtures.user_fixture(%{role: :buyer})
      product = valid_product_attributes(%{seller_id: buyer_user.id})
      {:error, changeset} = Products.create_product(product)
      assert %{seller_id: ["user must have a seller role"]} = errors_on(changeset)
    end

    test "validates amount_available" do
      product = valid_product_attributes(%{amount_available: -1})
      {:error, changeset} = Products.create_product(product)
      assert %{amount_available: ["must be greater than or equal to 0"]} = errors_on(changeset)

      product = valid_product_attributes(%{amount_available: 1_000_001})
      {:error, changeset} = Products.create_product(product)
      assert %{amount_available: ["must be less than or equal to 1000000"]} = errors_on(changeset)
    end

    test "validates cost" do
      product = valid_product_attributes(%{cost: 0})
      {:error, changeset} = Products.create_product(product)
      assert %{cost: ["must be greater than 0"]} = errors_on(changeset)

      product = valid_product_attributes(%{cost: 100_000_001})
      {:error, changeset} = Products.create_product(product)
      assert %{cost: ["must be less than or equal to 100000000"]} = errors_on(changeset)
    end

    test "validates product_name" do
      product = valid_product_attributes(%{product_name: ""})
      {:error, changeset} = Products.create_product(product)
      assert %{product_name: ["can't be blank"]} = errors_on(changeset)

      product = valid_product_attributes(%{product_name: String.duplicate("a", 1001)})
      {:error, changeset} = Products.create_product(product)
      assert %{product_name: ["should be at most 1000 character(s)"]} = errors_on(changeset)

      existing_product = product_fixture()

      product = valid_product_attributes(%{product_name: existing_product.product_name})
      {:error, changeset} = Products.create_product(product)
      assert %{product_name: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "update_product/2" do
    test "valid data updates the product" do
      product = product_fixture()

      update_attrs = %{
        amount_available: 43,
        cost: "456.7",
        product_name: "some updated product_name"
      }

      assert {:ok, %Product{} = product} = Products.update_product(product, update_attrs)
      assert product.amount_available == 43
      assert product.cost == Decimal.new("456.7")
      assert product.product_name == "some updated product_name"
    end

    test "invalid data returns error changeset" do
      product = product_fixture()
      assert {:error, %Ecto.Changeset{}} = Products.update_product(product, @invalid_attrs)
      assert product == Products.get_product!(product.id)
    end
  end

  describe "delete_product/1" do
    test "deletes the product" do
      product = product_fixture()
      assert {:ok, %Product{}} = Products.delete_product(product)
      assert_raise Ecto.NoResultsError, fn -> Products.get_product!(product.id) end
    end
  end

  describe "change_product/1" do
    test "returns a product changeset" do
      product = product_fixture()
      assert %Ecto.Changeset{} = Products.change_product(product)
    end
  end
end
