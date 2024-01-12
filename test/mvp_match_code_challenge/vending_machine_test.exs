defmodule MvpMatchCodeChallenge.VendingMachineTest do
  use MvpMatchCodeChallenge.DataCase, async: true

  import MvpMatchCodeChallenge.AccountsFixtures
  alias MvpMatchCodeChallenge.ProductsFixtures
  alias MvpMatchCodeChallenge.Products.Product
  alias MvpMatchCodeChallenge.Accounts.User
  alias MvpMatchCodeChallenge.VendingMachine

  describe "add_coin_to_user_deposit/2" do
    setup do
      %{user: user_fixture(%{role: :buyer})}
    end

    test "validates coin", %{user: user} do
      assert {:error, :invalid_coin} =
               VendingMachine.add_coin_to_user_deposit(user, 2)
    end

    test "validates whether user is buyer" do
      user = user_fixture(%{role: :seller})

      assert {:error, :not_implemented} =
               VendingMachine.add_coin_to_user_deposit(user, 5)
    end

    test "adds coin to user deposit", %{user: user} do
      coin = 5

      {:ok, updated_user} = VendingMachine.add_coin_to_user_deposit(user, coin)
      assert updated_user.deposit == user.deposit + coin
    end
  end

  describe "reset_user_deposit/1" do
    setup do
      %{user: user_fixture(%{role: :buyer, deposit: 110})}
    end

    test "validates whether user is buyer" do
      user = user_fixture(%{role: :seller})

      assert {:error, :not_implemented} =
               VendingMachine.reset_user_deposit(user)
    end

    test "resets user deposit", %{user: user} do
      assert user.deposit == 110
      {:ok, updated_user} = VendingMachine.reset_user_deposit(user)
      assert updated_user.deposit == 0
    end
  end

  describe "buy_product/3" do
    test "returns {:error, :insufficient_funds} if buyer has insufficient funds" do
      product = ProductsFixtures.product_fixture(%{amount_available: 1, cost: 6})

      buyer_with_little_deposit =
        user_fixture(%{
          deposit: 5
        })

      assert VendingMachine.buy_product(product, buyer_with_little_deposit, 1) ==
               {:error, :insufficient_funds}
    end

    test "returns {:error, :out_of_stock} if product is out of stock" do
      buyer = user_fixture(%{deposit: 100})
      product = ProductsFixtures.product_fixture(%{amount_available: 1, cost: 10})

      assert VendingMachine.buy_product(product, buyer, 2) ==
               {:error, :out_of_stock}
    end

    test "returns {:ok, result} if product can be bought" do
      product = ProductsFixtures.product_fixture(%{amount_available: 2, cost: 7})
      buyer = user_fixture(%{deposit: 100})

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
