defmodule MvpMatchCodeChallengeWeb.VendingMachineController do
  use MvpMatchCodeChallengeWeb, :controller

  alias MvpMatchCodeChallenge.VendingMachine
  alias MvpMatchCodeChallenge.Products

  action_fallback MvpMatchCodeChallengeWeb.FallbackController

  def buy(
        %{
          assigns: %{
            current_user:
              %{
                role: :buyer
              } = current_user
          }
        } = conn,
        %{"product_id" => product_id, "amount" => amount}
      ) do
    try do
      product = Products.get_product!(product_id)

      with {:ok, result} <- VendingMachine.buy_product(product, current_user, amount) do
        render(conn, :buy_transaction, result)
      end
    rescue
      Ecto.NoResultsError -> {:error, :not_found}
    end
  end

  def buy(_conn, _params), do: {:error, :bad_request}
end
