defmodule MvpMatchCodeChallengeWeb.ProductLiveTest do
  use MvpMatchCodeChallengeWeb.ConnCase, async: true

  alias MvpMatchCodeChallenge.AccountsFixtures

  import Phoenix.LiveViewTest
  import MvpMatchCodeChallenge.ProductsFixtures

  @create_attrs %{amount_available: 42, cost: "120.5", product_name: "some product_name"}
  @update_attrs %{amount_available: 43, cost: "456.7", product_name: "some updated product_name"}
  @invalid_attrs %{amount_available: nil, cost: nil, product_name: nil}

  describe "Index" do
    setup %{conn: conn} do
      current_user = AccountsFixtures.user_fixture(%{role: :seller})
      product_sold_by_current_user = product_fixture(%{seller_id: current_user.id})
      random_user = AccountsFixtures.user_fixture(%{role: :seller})
      random_product = product_fixture(%{seller_id: random_user.id})
      authenticated_conn = log_in_user(conn, current_user)

      %{
        current_user: current_user,
        product_sold_by_current_user: product_sold_by_current_user,
        random_product: random_product,
        conn: authenticated_conn,
        unauthenticated_conn: conn
      }
    end

    test "lists all products", %{
      unauthenticated_conn: conn,
      product_sold_by_current_user: product_sold_by_current_user,
      random_product: random_product
    } do
      {:ok, _index_live, html} = live(conn, ~p"/products")

      assert html =~ "All Products"
      assert html =~ "Want to add products or buy products?"
      assert html =~ product_sold_by_current_user.product_name
      assert html =~ random_product.product_name
    end

    test "lists products edit button for product owner", %{
      conn: conn,
      product_sold_by_current_user: product_sold_by_current_user,
      random_product: random_product
    } do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert index_live |> has_element?("#products-#{product_sold_by_current_user.id} a", "Edit")
      refute index_live |> has_element?("#products-#{random_product.id} a", "Edit")

      assert index_live
             |> has_element?("#products-#{product_sold_by_current_user.id} a", "Delete")

      refute index_live |> has_element?("#products-#{random_product.id} a", "Delete")
    end

    test "saves new product", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert index_live
             |> element("a", "New Product")
             |> render_click() =~
               "New Product"

      assert_patch(index_live, ~p"/products/new")

      assert index_live
             |> form("#product-form", product: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#product-form", product: @create_attrs)
             |> render_submit()

      html = render(index_live)
      assert html =~ @create_attrs.product_name
    end

    test "updates product in listing", %{conn: conn, product_sold_by_current_user: product} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert index_live
             |> element("#products-#{product.id} a", "Edit")
             |> render_click() =~
               "Edit Product"

      assert_patch(index_live, ~p"/products/#{product}/edit")

      assert index_live
             |> form("#product-form", product: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#product-form", product: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/products")

      html = render(index_live)
      assert html =~ "Product updated successfully"
      assert html =~ "some updated product_name"
    end

    test "deletes product in listing", %{conn: conn, product_sold_by_current_user: product} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert index_live
             |> element("#products-#{product.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#products-#{product.id}")
    end
  end

  describe "Show" do
    setup %{conn: conn} do
      current_user = AccountsFixtures.user_fixture(%{role: :seller})
      product_sold_by_current_user = product_fixture(%{seller_id: current_user.id})
      random_user = AccountsFixtures.user_fixture(%{role: :seller})
      random_product = product_fixture(%{seller_id: random_user.id})
      authenticated_conn = log_in_user(conn, current_user)

      %{
        current_user: current_user,
        product_sold_by_current_user: product_sold_by_current_user,
        random_product: random_product,
        conn: authenticated_conn,
        unauthenticated_conn: conn
      }
    end

    test "displays product", %{conn: conn, product_sold_by_current_user: product} do
      {:ok, _show_live, html} = live(conn, ~p"/products/#{product}")

      assert html =~ "Show Product"
      assert html =~ product.product_name
      assert html =~ "Edit"
    end

    test "hides edit link for non sellers", %{conn: conn, random_product: product} do
      {:ok, _show_live, html} = live(conn, ~p"/products/#{product}")

      refute html =~ "Edit"
    end

    test "redirects if user is not product seller ", %{conn: conn, random_product: product} do
      assert {:error, redirect} = live(conn, ~p"/products/#{product}/edit")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/products"
      assert %{"error" => "You must be the seller of the product to access this page."} = flash

      assert {:error, redirect_from_show} = live(conn, ~p"/products/#{product}/show/edit")

      assert {:redirect, %{to: path, flash: flash}} = redirect_from_show
      assert path == ~p"/products"
      assert %{"error" => "You must be the seller of the product to access this page."} = flash
    end

    test "updates product within modal", %{conn: conn, product_sold_by_current_user: product} do
      {:ok, show_live, _html} = live(conn, ~p"/products/#{product}")

      assert show_live
             |> element("a", "Edit")
             |> render_click() =~
               "Edit Product"

      assert_patch(show_live, ~p"/products/#{product}/show/edit")

      assert show_live
             |> form("#product-form", product: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#product-form", product: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/products/#{product}")

      html = render(show_live)
      assert html =~ "Product updated successfully"
      assert html =~ @update_attrs.product_name
    end
  end
end
