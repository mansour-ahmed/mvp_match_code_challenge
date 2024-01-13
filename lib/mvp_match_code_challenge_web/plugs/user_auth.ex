defmodule MvpMatchCodeChallengeWeb.UserAuth do
  use MvpMatchCodeChallengeWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller
  alias MvpMatchCodeChallenge.Accounts

  @login_required_message "You must log in to access this page."

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
        |> Phoenix.LiveView.put_flash(:error, @login_required_message)
        |> Phoenix.LiveView.redirect(to: log_in_path())

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  def on_mount(:ensure_seller_user, _params, session, socket) do
    socket = mount_current_user(socket, session)
    user_role = Map.get(socket.assigns.current_user, :role)

    if user_role == :seller do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must be a seller to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/")

      {:halt, socket}
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

  def redirect_if_user_is_authenticated(
        %{
          assigns: %{
            current_user: %{
              id: _
            }
          }
        } = conn,
        _opts
      ) do
    conn
    |> redirect(to: signed_in_path(conn))
    |> halt()
  end

  def redirect_if_user_is_authenticated(conn, _opts), do: conn

  @doc """
  Used for routes that require the user to be authenticated.
  """
  def require_authenticated_user(
        %{
          assigns: %{
            current_user: %{
              id: _
            }
          }
        } = conn,
        _opts
      ),
      do: conn

  def require_authenticated_user(conn, _opts) do
    conn
    |> put_flash(:error, @login_required_message)
    |> maybe_store_return_to()
    |> redirect(to: log_in_path())
    |> halt()
  end

  def require_seller_user(%{assigns: %{current_user: %{role: :seller}}} = conn, _opts), do: conn

  def require_seller_user(conn, _opts) do
    conn
    |> put_flash(:error, "You must be a seller to access this page.")
    |> redirect(to: ~p"/")
    |> halt()
  end

  defp signed_in_path(_conn), do: ~p"/"

  defp log_in_path(), do: ~p"/users/log_in"

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn
end
