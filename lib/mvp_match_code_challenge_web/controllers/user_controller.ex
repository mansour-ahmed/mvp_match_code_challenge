defmodule MvpMatchCodeChallengeWeb.UserController do
  use MvpMatchCodeChallengeWeb, :controller

  alias MvpMatchCodeChallenge.VendingMachine
  alias MvpMatchCodeChallenge.Accounts

  action_fallback MvpMatchCodeChallengeWeb.FallbackController

  def show(conn, %{"id" => id}) do
    try do
      case Accounts.get_user(id) do
        nil ->
          {:error, :not_found}

        user ->
          render(conn, :show, user: user)
      end
    rescue
      Ecto.Query.CastError -> {:error, :bad_request}
      _ -> {:error, :internal_server_error}
    end
  end

  def create(conn, user_params) do
    with {:ok, %Accounts.User{} = user} <- Accounts.register_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/users/#{user}")
      |> render(:show, user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user(id)

    case user do
      nil ->
        {:error, :not_found}

      _ ->
        with :ok <- Accounts.delete_user(user) do
          send_resp(conn, :no_content, "")
        end
    end
  end

  def reset_deposit(conn, %{"id" => id}) do
    with {:ok, user} <- get_user(id),
         {:ok, updated_user} <- VendingMachine.reset_user_deposit(user) do
      render(conn, :show, user: updated_user)
    else
      {:error, :not_found} ->
        {:error, :not_found}

      _ ->
        {:error, :internal_server_error}
    end
  end

  def deposit(conn, %{"id" => id, "coin" => coin}) do
    with {:ok, user} <- get_user(id),
         {:ok, parsed_coin} <- parse_coin(coin),
         {:ok, user} <- VendingMachine.add_coin_to_user_deposit(user, parsed_coin) do
      render(conn, :show, user: user)
    else
      {:error, :invalid_coin} ->
        {:error, :bad_request, "Invalid coin value. Only 5, 10, 20, 50, 100 coins are allowed."}

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :bad_request} ->
        {:error, :bad_request}

      _ ->
        {:error, :internal_server_error}
    end
  end

  defp get_user(id) do
    case Accounts.get_user(id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  rescue
    Ecto.Query.CastError -> {:error, :bad_request}
    _ -> {:error, :internal_server_error}
  end

  defp parse_coin(coin) do
    case Integer.parse(coin) do
      :error -> {:error, :invalid_coin}
      {parsed_coin, _} -> {:ok, parsed_coin}
    end
  end
end
