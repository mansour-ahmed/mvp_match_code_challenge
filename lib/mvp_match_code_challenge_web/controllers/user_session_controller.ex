defmodule MvpMatchCodeChallengeWeb.UserSessionController do
  use MvpMatchCodeChallengeWeb, :controller

  alias MvpMatchCodeChallenge.Accounts
  alias MvpMatchCodeChallengeWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  def create_api_token(conn, %{"user" => user_params}) do
    %{"username" => username, "password" => password} = user_params

    if user = Accounts.get_user_by_username_and_password(username, password) do
      token = Accounts.create_user_api_token(user)

      conn
      |> send_resp(:ok, token)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the username is registered.
      conn
      |> send_resp(:unauthorized, "Invalid username or password")
    end
  end

  def create_api_token(conn, _params) do
    conn
    |> send_resp(:bad_request, "Invalid params")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"username" => username, "password" => password} = user_params

    if user = Accounts.get_user_by_username_and_password(username, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the username is registered.
      conn
      |> put_flash(:error, "Invalid username or password")
      |> put_flash(:username, String.slice(username, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
