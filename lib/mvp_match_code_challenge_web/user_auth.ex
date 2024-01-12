defmodule MvpMatchCodeChallengeWeb.UserAuth do
  use MvpMatchCodeChallengeWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias MvpMatchCodeChallenge.{ApiTokens, Accounts, Products}
  alias MvpMatchCodeChallenge.Accounts.UserToken

  @max_age 60 * 60 * 24 * UserToken.get_session_validity_in_days()
  @remember_me_cookie "_mvp_match_code_challenge_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax", http_only: true]

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: user_return_to || signed_in_path(conn))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_user_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      MvpMatchCodeChallengeWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

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
  Handles mounting and authenticating the current_user in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_user` - Assigns current_user
      to socket assigns based on user_token, or nil if
      there's no user_token or no matching user.

    * `:ensure_authenticated` - Authenticates the user from the session,
      and assigns the current_user to socket assigns based
      on user_token.
      Redirects to login page if there's no logged user.

    * `:redirect_if_user_is_authenticated` - Authenticates the user from the session.
      Redirects to signed_in_path if there's a logged user.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the current_user:

      defmodule MvpMatchCodeChallengeWeb.PageLive do
        use MvpMatchCodeChallengeWeb, :live_view

        on_mount {MvpMatchCodeChallengeWeb.UserAuth, :mount_current_user}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{MvpMatchCodeChallengeWeb.UserAuth, :ensure_authenticated}] do
        live "/profile", ProfileLive, :index
      end
  """
  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/users/log_in")

      {:halt, socket}
    end
  end

  def on_mount(
        :ensure_product_seller,
        %{"id" => product_id} = _params,
        _session,
        %{assigns: %{current_user: current_user}} = socket
      ) do
    product = Products.get_product_by_seller_id(product_id, current_user.id)

    if product do
      socket = Phoenix.Component.assign(socket, :product, product)
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(
          :error,
          "You must be the seller of the product to access this page."
        )
        |> Phoenix.Component.assign(:product, nil)
        |> Phoenix.LiveView.redirect(to: ~p"/products")

      {:halt, socket}
    end
  end

  def on_mount(
        :ensure_product_seller,
        _params,
        _session,
        socket
      ) do
    socket =
      socket
      |> Phoenix.LiveView.put_flash(
        :error,
        "You must be the seller of the product to access this page."
      )
      |> Phoenix.Component.assign(:product, nil)
      |> Phoenix.LiveView.redirect(to: ~p"/products")

    {:halt, socket}
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user_token = session["user_token"] do
        Accounts.get_user_by_session_token(user_token)
      end
    end)
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/log_in")
      |> halt()
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

  def api_require_product_seller(
        %{assigns: %{current_user: %{id: user_id}}, params: %{"id" => product_id}} = conn,
        _opts
      ) do
    product = Products.get_product_by_seller_id(product_id, user_id)

    if product do
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

  def api_require_product_seller(
        conn,
        _opts
      ) do
    conn
    |> send_resp(
      :unauthorized,
      "You must be the seller of the product to access this resource."
    )
    |> halt()
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

  def require_product_seller(
        %{assigns: %{current_user: %{id: user_id}}, params: %{"id" => product_id}} = conn,
        _opts
      ) do
    product = Products.get_product_by_seller_id(product_id, user_id)

    if product do
      conn
    else
      conn
      |> put_flash(:error, "You must be the seller of the product to access this page.")
      |> redirect(to: ~p"/products")
      |> halt()
    end
  end

  def require_product_seller(
        conn,
        _opts
      ) do
    conn
    |> put_flash(:error, "You must be the seller of the product to access this page.")
    |> redirect(to: ~p"/products")
    |> halt()
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/"
end
