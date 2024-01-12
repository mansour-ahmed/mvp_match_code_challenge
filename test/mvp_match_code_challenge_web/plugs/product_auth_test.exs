defmodule MvpMatchCodeChallengeWeb.ProductAuthTest do
  use MvpMatchCodeChallengeWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias MvpMatchCodeChallenge.{Accounts, ProductsFixtures}
  alias MvpMatchCodeChallengeWeb.ProductAuth
  import MvpMatchCodeChallenge.AccountsFixtures

  setup %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{})

    %{user: user_fixture(%{role: :seller}), conn: conn}
  end

  describe "on_mount: ensure_product_seller" do
    setup %{conn: conn, user: user} do
      product = ProductsFixtures.product_fixture(%{seller_id: user.id})
      %{conn: conn, user: user, product: product}
    end

    test "redirects to products page if there isn't a valid user_token", %{
      conn: conn,
      product: product
    } do
      user_token = "invalid_token"

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: MvpMatchCodeChallengeWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} =
        ProductAuth.on_mount(:ensure_product_seller, %{"id" => product.id}, session, socket)

      assert Map.get(updated_socket.assigns, :product) == nil
    end

    test "redirects to products page if given user isn't product seller", %{
      conn: conn,
      product: product
    } do
      random_user = user_fixture(%{role: :seller})
      user_token = Accounts.generate_user_session_token(random_user)

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      {:halt, updated_socket} =
        ProductAuth.on_mount(
          :ensure_product_seller,
          %{"id" => product.id},
          session,
          %LiveView.Socket{
            assigns: %{__changed__: %{}, flash: %{}, current_user: random_user}
          }
        )

      assert Map.get(updated_socket.assigns, :product) == nil
    end
  end

  describe "api_require_product_seller/2" do
    setup %{conn: conn, user: user} do
      product = ProductsFixtures.product_fixture(%{seller_id: user.id})
      %{conn: conn, user: user, product: product}
    end

    test "responds with 401 if product id is not valid", %{conn: conn} do
      random_user = user_fixture(%{role: :seller})
      params = %{"id" => -1}

      conn =
        %{conn | params: params}
        |> assign(:current_user, random_user)
        |> fetch_flash()
        |> ProductAuth.api_require_product_seller([])

      assert conn.halted
      assert conn.status == 401
      assert conn.resp_body == "You must be the seller of the product to access this resource."
    end

    test "responds with 401 if user is not authenticated", %{conn: conn, product: product} do
      params = %{"id" => product.id}

      conn =
        %{conn | params: params}
        |> fetch_flash()
        |> ProductAuth.api_require_product_seller([])

      assert conn.halted
      assert conn.status == 401
      assert conn.resp_body == "You must be the seller of the product to access this resource."
    end

    test "responds with 401 if user is not product seller", %{conn: conn, product: product} do
      random_user = user_fixture(%{role: :seller})
      params = %{"id" => product.id}

      conn =
        %{conn | params: params}
        |> assign(:current_user, random_user)
        |> fetch_flash()
        |> ProductAuth.api_require_product_seller([])

      assert conn.halted
      assert conn.status == 401
      assert conn.resp_body == "You must be the seller of the product to access this resource."
    end

    test "does not respond with 401 if user is product seller", %{
      conn: conn,
      user: user,
      product: product
    } do
      params = %{"id" => product.id}

      conn =
        %{conn | params: params}
        |> assign(:current_user, user)
        |> ProductAuth.api_require_product_seller([])

      refute conn.halted
      refute conn.status
    end
  end

  describe "require_product_seller/2" do
    setup %{conn: conn, user: user} do
      product = ProductsFixtures.product_fixture(%{seller_id: user.id})
      %{conn: conn, user: user, product: product}
    end

    test "redirects if product id is not valid", %{conn: conn} do
      random_user = user_fixture(%{role: :seller})
      params = %{"id" => -1}

      conn =
        %{conn | params: params}
        |> assign(:current_user, random_user)
        |> fetch_flash()
        |> ProductAuth.require_product_seller([])

      assert conn.halted
      assert redirected_to(conn) == ~p"/products"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must be the seller of the product to access this page."
    end

    test "redirects if user is not authenticated", %{conn: conn, product: product} do
      params = %{"id" => product.id}

      conn =
        %{conn | params: params}
        |> fetch_flash()
        |> ProductAuth.require_product_seller([])

      assert conn.halted
      assert redirected_to(conn) == ~p"/products"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must be the seller of the product to access this page."
    end

    test "redirects if user is not product seller", %{conn: conn, product: product} do
      random_user = user_fixture(%{role: :seller})
      params = %{"id" => product.id}

      conn =
        %{conn | params: params}
        |> assign(:current_user, random_user)
        |> fetch_flash()
        |> ProductAuth.require_product_seller([])

      assert conn.halted
      assert redirected_to(conn) == ~p"/products"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must be the seller of the product to access this page."
    end

    test "does not redirect if user is product seller", %{
      conn: conn,
      user: user,
      product: product
    } do
      params = %{"id" => product.id}

      conn =
        %{conn | params: params}
        |> assign(:current_user, user)
        |> ProductAuth.require_product_seller([])

      refute conn.halted
      refute conn.status
    end
  end
end
