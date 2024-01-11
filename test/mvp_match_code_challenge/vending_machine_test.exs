defmodule MvpMatchCodeChallenge.VendingMachineTest do
  @moduledoc false
  alias MvpMatchCodeChallenge.Products.Product
  alias MvpMatchCodeChallenge.Accounts.User
  alias MvpMatchCodeChallenge.AccountsFixtures
  alias MvpMatchCodeChallenge.ProductsFixtures
  use MvpMatchCodeChallenge.DataCase, async: true

  alias MvpMatchCodeChallenge.VendingMachine

  describe "coin_valid?/1" do
    test "returns true if coin is valid" do
      assert VendingMachine.coin_valid?(100) == true
      assert VendingMachine.coin_valid?(50) == true
      assert VendingMachine.coin_valid?(20) == true
      assert VendingMachine.coin_valid?(10) == true
      assert VendingMachine.coin_valid?(5) == true
    end

    test "returns false if coin is invalid" do
      assert VendingMachine.coin_valid?(1) == false
    end
  end

  describe "buy_product/3" do
    test "returns {:error, :insufficient_funds} if buyer has insufficient funds" do
      product = ProductsFixtures.product_fixture(%{amount_available: 1, cost: 6})

      buyer_with_little_deposit =
        AccountsFixtures.user_fixture(%{
          deposit: 5
        })

      assert VendingMachine.buy_product(product, buyer_with_little_deposit, 1) ==
               {:error, :insufficient_funds}
    end

    test "returns {:error, :out_of_stock} if product is out of stock" do
      buyer = AccountsFixtures.user_fixture(%{deposit: 100})
      product = ProductsFixtures.product_fixture(%{amount_available: 1, cost: 10})

      assert VendingMachine.buy_product(product, buyer, 2) ==
               {:error, :out_of_stock}
    end

    test "returns {:ok, result} if product can be bought" do
      product = ProductsFixtures.product_fixture(%{amount_available: 2, cost: 7})
      buyer = AccountsFixtures.user_fixture(%{deposit: 100})

      assert VendingMachine.buy_product(product, buyer, 2) ==
               {:ok,
                %{
                  product: %{product | amount_available: 0},
                  total_cost_to_buyer: 15,
                  change_after_transaction_in_coins: [50, 20, 10, 5]
                }}

      assert Repo.get_by(User, id: buyer.id).deposit == 85
      assert Repo.get_by(Product, id: product.id).amount_available == 0
    end
  end
end
