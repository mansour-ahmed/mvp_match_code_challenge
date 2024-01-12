defmodule MvpMatchCodeChallengeWeb.ApiAuth do
  use MvpMatchCodeChallengeWeb, :verified_routes

  alias MvpMatchCodeChallenge.{Accounts, ApiTokens}
  import Plug.Conn

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
  Used for routes that require the user to be authenticated.
  """
  def api_require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> send_resp(:unauthorized, "You must use a valid token to access this resource.")
      |> halt()
    end
  end

  def api_require_user_admin(
        %{assigns: %{current_user: %{id: current_user_id}}, params: %{"id" => user_id}} = conn,
        _opts
      ) do
    user = Accounts.get_user(user_id)

    # return 'not authorized' even if user is not found to avoid user enumeration attacks
    if user && user.id === current_user_id do
      conn
    else
      conn
      |> send_resp(
        :unauthorized,
        "Not authorized"
      )
      |> halt()
    end
  end

  def api_require_user_admin(
        conn,
        _opts
      ) do
    conn
    |> send_resp(
      :unauthorized,
      "Not authorized"
    )
    |> halt()
  end
end
