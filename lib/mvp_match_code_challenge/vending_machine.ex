defmodule MvpMatchCodeChallenge.VendingMachine do
  alias MvpMatchCodeChallenge.Products.{Product, ProductTransaction}
  alias MvpMatchCodeChallenge.{Repo, Accounts, Accounts.User}
  alias Decimal, as: D

  @valid_coins [100, 50, 20, 10, 5]

  def get_valid_coins, do: @valid_coins

  @doc """
  Adds a specified coin value to given user's deposit.
  Valid only for users with the `:buyer` role and when using valid coin denominations.
  """
  def add_coin_to_user_deposit(user, coin) when is_integer(coin) do
    if Enum.member?(@valid_coins, coin) do
      user |> Accounts.update_user_deposit(%{deposit: coin + user.deposit})
    else
      {:error, :invalid_coin}
    end
  end

  @doc """
  Resets the user's deposit to zero. Permitted only for users with the `:buyer` role.
  """
  def reset_user_deposit(user),
    do: user |> Accounts.update_user_deposit(%{deposit: 0})

  @doc """
  Handles the purchase of products by given user.
  Verifies fund sufficiency, stock availability, and calculates the change to be returned.
  """
  def buy_product(%Product{} = product, %User{} = buyer, transaction_product_amount)
      when is_integer(transaction_product_amount) do
    total_product_cost = D.mult(product.cost, transaction_product_amount)
    buyer_balance = D.new(buyer.deposit)

    changeset =
      transaction_changeset(%{
        transaction_product_amount: transaction_product_amount,
        product_total_cost: total_product_cost,
        product_available_amount: product.amount_available,
        buyer_available_funds: buyer_balance
      })

    if changeset.valid? do
      buy_product_transaction(
        buyer_balance,
        total_product_cost,
        buyer,
        product,
        transaction_product_amount
      )
    else
      {:error, changeset}
    end
  end

  def transaction_changeset(attrs) do
    ProductTransaction.changeset(attrs)
  end

  defp buy_product_transaction(balance, total_cost, buyer, product, transaction_product_amount) do
    {_, change_coins} = calculate_change(balance, total_cost)
    new_balance = Enum.sum(change_coins)
    new_amount_available = product.amount_available - transaction_product_amount

    total_cost_after_transaction =
      balance
      |> Decimal.sub(new_balance)
      |> Decimal.to_integer()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:buyer, User.deposit_changeset(buyer, %{deposit: new_balance}))
    |> Ecto.Multi.update(
      :product,
      Product.amount_available_changeset(product, %{amount_available: new_amount_available})
    )
    |> Repo.transaction()
    |> transaction_result(total_cost_after_transaction, change_coins)
  end

  defp transaction_result({:ok, %{product: product}}, total_cost_after_transaction, change_coins) do
    {:ok,
     %{
       product: product,
       total_cost_to_buyer: total_cost_after_transaction,
       change_after_transaction_in_coins: change_coins
     }}
  end

  defp transaction_result({:error, _}, _, _), do: {:error, :transaction_failed}

  defp calculate_change(amount, total_cost) do
    change = D.sub(amount, total_cost)
    Enum.reduce(descending_valid_coins(), {change, []}, &accumulate_change/2)
  end

  defp accumulate_change(coin, {remaining, coins_list}) do
    if remaining < D.new(coin) do
      {remaining, coins_list}
    else
      count =
        remaining
        |> D.div(D.new(coin))
        |> D.round(0, :down)
        |> D.to_integer()

      new_remaining = D.rem(remaining, D.new(coin))
      {new_remaining, coins_list ++ List.duplicate(coin, count)}
    end
  end

  defp descending_valid_coins, do: Enum.sort(@valid_coins, &(&2 < &1))
end
