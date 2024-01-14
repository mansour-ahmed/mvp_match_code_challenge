defmodule MvpMatchCodeChallengeWeb.ProductAuth do
  use MvpMatchCodeChallengeWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller
  alias MvpMatchCodeChallenge.Products

  @not_authored_message "You must be the seller of the product to access this"

  def on_mount(:ensure_product_seller, params, _session, socket) do
    user = Map.get(socket.assigns, :current_user)
    product_id = params["id"]

    authorize_action(product_id, user, socket, method: :socket)
  end

  def require_product_seller(conn, _opts) do
    user = Map.get(conn.assigns, :current_user)
    product_id = conn.params["id"]

    authorize_action(product_id, user, conn, method: :conn)
  end

  def api_require_product_seller(conn, _opts) do
    user = Map.get(conn.assigns, :current_user)
    product_id = conn.params["id"]

    authorize_action(product_id, user, conn, method: :api_conn)
  end

  defp authorize_action(_, nil, conn, method: :api_conn),
    do:
      conn
      |> send_resp(:unauthorized, "You must log in to access this resource.")
      |> halt()

  defp authorize_action(_, nil, context, opts), do: halt_context(context, opts[:method])

  defp authorize_action(product_id, user, context, opts) do
    if user_is_product_seller?(product_id, user.id) do
      continue_context(context, opts[:method])
    else
      halt_context(context, opts[:method])
    end
  end

  defp user_is_product_seller?(product_id, user_id) do
    try do
      Products.get_product_by_seller_id(product_id, user_id) != nil
    rescue
      _ -> false
    end
  end

  defp continue_context(context, :socket), do: {:cont, context}
  defp continue_context(context, _), do: context

  defp halt_context(socket, :socket) do
    socket
    |> Phoenix.LiveView.put_flash(:error, error_message())
    |> Phoenix.Component.assign(:product, nil)
    |> Phoenix.LiveView.redirect(to: ~p"/products")

    {:halt, socket}
  end

  defp halt_context(conn, :conn) do
    conn
    |> put_flash(:error, error_message())
    |> redirect(to: ~p"/products")
    |> halt()
  end

  defp halt_context(conn, :api_conn) do
    conn
    |> send_resp(:forbidden, "#{@not_authored_message} resource.")
    |> halt()
  end

  defp error_message, do: "#{@not_authored_message} page."
end
