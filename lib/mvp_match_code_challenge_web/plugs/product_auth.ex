defmodule MvpMatchCodeChallengeWeb.ProductAuth do
  use MvpMatchCodeChallengeWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias MvpMatchCodeChallenge.Products

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
end
