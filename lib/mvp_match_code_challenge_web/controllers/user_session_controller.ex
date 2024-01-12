defmodule MvpMatchCodeChallengeWeb.UserSessionController do
  use MvpMatchCodeChallengeWeb, :controller

  alias MvpMatchCodeChallenge.Accounts
  alias MvpMatchCodeChallengeWeb.UserAuth

  action_fallback MvpMatchCodeChallengeWeb.FallbackController

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

  def create_api_token(conn, %{"user" => user_params}) do
    %{"username" => username, "password" => password} = user_params

    if user = Accounts.get_user_by_username_and_password(username, password) do
      token = Accounts.create_user_api_token(user)

      %{api_token_count: api_token_count, session_token_count: session_token_count} =
        Accounts.get_user_active_tokens_count(user)

      conn
      |> put_status(:ok)
      |> json(%{
        data: %{
          token: token,
          tokens_count:
            "You have #{api_token_count} active API tokens and #{session_token_count} web sessions. You can log out of all sessions by visiting api/users/log_out/all"
        }
      })
    else
      # In order to prevent user enumeration attacks, don't disclose whether the username is registered.
      conn
      |> send_resp(:unauthorized, "Invalid username or password")
    end
  end

  def create_api_token(_conn, _params), do: {:error, :bad_request}

  def delete_all_tokens(
        %{
          assigns: %{
            current_user: current_user
          }
        } = conn,
        _params
      ) do
    try do
      Accounts.delete_all_user_tokens(current_user)

      conn
      |> put_status(:ok)
      |> json(%{
        data: %{
          message: "All tokens have been deleted."
        }
      })
    rescue
      _ -> {:error, :internal_server_error}
    end
  end
end
