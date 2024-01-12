defmodule MvpMatchCodeChallengeWeb.ApiAuth do
  use MvpMatchCodeChallengeWeb, :verified_routes

  alias MvpMatchCodeChallenge.{Accounts, ApiTokens}
  import Plug.Conn

  @unauthorized_message "Not authorized"

  def fetch_api_user(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user} <- ApiTokens.fetch_user_by_api_token(token) do
      assign(conn, :current_user, user)
    else
      _ ->
        assign(conn, :current_user, nil)
    end
  end

  @doc """
  Requires the user to be authenticated to access the route.
  """
  def api_require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      unauthorized_response(conn, "You must use a valid token to access this resource.")
    end
  end

  @doc """
  Requires the current user to be an admin of the specified user.
  """
  def api_require_user_admin(conn, opts) do
    case conn.assigns[:current_user] do
      %{id: current_user_id} ->
        check_user_admin(conn, current_user_id, opts)

      _ ->
        unauthorized_response(conn, @unauthorized_message)
    end
  end

  defp check_user_admin(%{params: %{"id" => user_id}} = conn, current_user_id, _) do
    user = Accounts.get_user(user_id)

    if user && user.id === current_user_id do
      conn
    else
      unauthorized_response(conn, @unauthorized_message)
    end
  end

  defp check_user_admin(conn, _, _), do: unauthorized_response(conn, @unauthorized_message)

  defp unauthorized_response(conn, message) do
    conn
    |> send_resp(:unauthorized, message)
    |> halt()
  end
end
