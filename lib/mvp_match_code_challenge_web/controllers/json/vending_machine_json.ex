defmodule MvpMatchCodeChallengeWeb.VendingMachineJSON do
  alias MvpMatchCodeChallenge.Products.Product

  def buy_transaction(%{
        product: product,
        total_cost_to_buyer: total_cost_to_buyer,
        change_after_transaction_in_coins: change_after_transaction_in_coins
      }) do
    %{
      data: %{
        product: data(product),
        total_cost_to_buyer: total_cost_to_buyer,
        change_after_transaction_in_coins: change_after_transaction_in_coins
      }
    }
  end

  defp data(%Product{} = product) do
    %{
      id: product.id,
      product_name: product.product_name,
      cost: product.cost
    }
  end
end
