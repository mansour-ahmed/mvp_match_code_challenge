defmodule MvpMatchCodeChallengeWeb.UserController do
  use MvpMatchCodeChallengeWeb, :controller

  alias MvpMatchCodeChallenge.Accounts

  action_fallback MvpMatchCodeChallengeWeb.FallbackController

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user(id)

    case user do
      nil ->
        {:error, :not_found}

      _ ->
        render(conn, :show, user: user)
    end
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, %Accounts.User{} = user} <- Accounts.register_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/users/#{user}")
      |> render(:show, user: user)
    end
  end

  def create(_conn, _params), do: {:error, :bad_request}

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
    user = Accounts.get_user(id)

    case user do
      nil ->
        {:error, :not_found}

      _ ->
        with {:ok, user} <- Accounts.reset_user_deposit(user) do
          render(conn, :show, user: user)
        end
    end
  end

  def deposit(conn, %{"id" => id, "coin" => coin}) do
    user = Accounts.get_user(id)

    parsed_coin =
      try do
        String.to_integer(coin)
      rescue
        _ -> {:error, :bad_request}
      end

    case user do
      nil ->
        {:error, :not_found}

      _ ->
        case Accounts.add_coin_to_user_deposit(user, parsed_coin) do
          {:ok, user} ->
            render(conn, :show, user: user)

          {:error, :invalid_coin} ->
            {:error, :bad_request,
             "Invalid coin value. Only 5, 10, 20, 50, 100 coins are allowed."}

          {:error, _} ->
            {:error, :bad_request}
        end
    end
  end
end
