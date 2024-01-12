defmodule MvpMatchCodeChallenge.VendingMachine do
  alias MvpMatchCodeChallenge.Repo
  alias MvpMatchCodeChallenge.Products.Product
  alias MvpMatchCodeChallenge.Accounts.User
  alias MvpMatchCodeChallenge.Accounts

  @valid_coins [100, 50, 20, 10, 5]

  @doc """
  Adds a specified coin value to a user's deposit. Only valid for users with
  the `:buyer` role and when using valid coin denominations.
  """
  def add_coin_to_user_deposit(%User{role: :buyer} = user, coin) when is_integer(coin) do
    if coin_valid?(coin) do
      user
      |> Accounts.update_user_deposit(%{deposit: coin + user.deposit})
    else
      {:error, :invalid_coin}
    end
  end

  def add_coin_to_user_deposit(_, _coin), do: {:error, :not_implemented}

  defp coin_valid?(coin) do
    Enum.member?(@valid_coins, coin)
  end

  @doc """
  Resets the user's deposit to zero. This action is only permitted for users
  with the `:buyer` role.
  """
  def reset_user_deposit(%User{role: :buyer} = user) do
    user
    |> Accounts.update_user_deposit(%{deposit: 0})
  end

  def reset_user_deposit(_), do: {:error, :not_implemented}

  def buy_product(%Product{} = product, %User{} = buyer, products_amount) do
    total_product_cost = Decimal.mult(product.cost, products_amount)
    buyer_balance = buyer.deposit |> Decimal.new()

    cond do
      buyer_balance < total_product_cost ->
        {:error, :insufficient_funds}

      product.amount_available < products_amount ->
        {:error, :out_of_stock}

      true ->
        {_, change_in_coins} = get_change_in_coins(buyer_balance, total_product_cost)
        buyer_new_balance = change_in_coins |> sum_up_coins
        product_new_amount_available = product.amount_available - products_amount

        Ecto.Multi.new()
        |> Ecto.Multi.update(:buyer, User.deposit_changeset(buyer, %{deposit: buyer_new_balance}))
        |> Ecto.Multi.update(
          :product,
          Product.amount_available_changeset(product, %{
            amount_available: product_new_amount_available
          })
        )
        |> Repo.transaction()
        |> case do
          {:ok, %{product: product}} ->
            {:ok,
             %{
               product: product,
               total_cost_to_buyer:
                 buyer_balance
                 |> Decimal.sub(buyer_new_balance)
                 |> Decimal.to_integer(),
               change_after_transaction_in_coins: change_in_coins
             }}

          {:error, _} ->
            {:error, :transaction_failed}
        end
    end
  end

  defp sum_up_coins(coins) do
    Enum.reduce(coins, 0, fn coin, sum -> sum + coin end)
  end

  defp get_change_in_coins(amount, total_cost) do
    total_change = Decimal.sub(amount, total_cost)

    get_valid_coins_desc()
    |> Enum.reduce({total_change, []}, fn coin, {remaining, coins_list} ->
      coin_is_too_large = remaining < coin

      if coin_is_too_large do
        {remaining, coins_list}
      else
        count =
          remaining
          |> Decimal.div(coin)
          |> Decimal.round(0, :down)
          |> Decimal.to_integer()

        new_remaining =
          remaining
          |> Decimal.rem(coin)
          |> Decimal.round(0, :down)
          |> Decimal.to_integer()

        {new_remaining, coins_list ++ List.duplicate(coin, count)}
      end
    end)
  end

  defp get_valid_coins_desc() do
    @valid_coins
    |> Enum.sort(fn coin1, coin2 -> coin2 < coin1 end)
  end
end
