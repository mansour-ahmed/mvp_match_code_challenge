defmodule MvpMatchCodeChallengeWeb.VendingMachineController do
  use MvpMatchCodeChallengeWeb, :controller

  alias Ecto.Changeset
  alias MvpMatchCodeChallenge.VendingMachine
  alias MvpMatchCodeChallenge.Products

  action_fallback MvpMatchCodeChallengeWeb.FallbackController

  def buy(
        %{
          assigns: %{
            current_user: current_user
          }
        } = conn,
        %{"id" => product_id, "transaction_product_amount" => amount}
      ) do
    try do
      product = Products.get_product!(product_id)

      case VendingMachine.buy_product(product, current_user, amount) do
        {:ok, result} ->
          render(conn, :buy_transaction, result)

        {:error, %Changeset{} = changeset} ->
          {:error, changeset}

        _ ->
          {:error, :internal_server_error}
      end
    rescue
      Ecto.NoResultsError -> {:error, :not_found}
    end
  end

  def buy(_conn, _params), do: {:error, :bad_request}
end
