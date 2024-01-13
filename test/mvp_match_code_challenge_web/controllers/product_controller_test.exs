defmodule MvpMatchCodeChallengeWeb.ProductControllerTest do
  use MvpMatchCodeChallengeWeb.ConnCase, async: true

  import MvpMatchCodeChallenge.ProductsFixtures
  alias MvpMatchCodeChallenge.{ApiTokens, AccountsFixtures}
  alias MvpMatchCodeChallenge.Products.Product

  setup %{
    conn: conn
  } do
    user = AccountsFixtures.user_fixture(%{role: :seller})
    user_token = ApiTokens.create_user_api_token(user)
    product = product_fixture(%{seller_id: user.id})
    random_product = product_fixture()

    conn_with_token = put_req_header(conn, "authorization", "Bearer #{user_token}")

    %{
      conn: conn,
      user: user,
      product: product,
      random_product: random_product,
      user_token: user_token,
      conn_with_token: conn_with_token
    }
  end

  describe "index" do
    test "lists all products", %{conn: conn, product: product, random_product: random_product} do
      conn = get(conn, ~p"/api/products")
      products_in_json = [product, random_product] |> Enum.map(&product_json/1)
      assert json_response(conn, 200)["data"] == products_in_json
    end
  end

  describe "show" do
    test "lists all products", %{conn: conn, product: product} do
      conn = get(conn, ~p"/api/products/#{product}")
      product_in_json = product_json(product)
      assert json_response(conn, 200)["data"] == product_in_json
    end
  end

  describe "create product" do
    test "renders errors when user is not logged in", %{conn: conn} do
      conn = post(conn, ~p"/api/products", product: valid_product_attributes())
      assert response(conn, 401) == "You must use a valid token to access this resource."
    end

    test "renders errors when data is invalid", %{conn_with_token: conn} do
      conn = post(conn, ~p"/api/products", product: %{})

      assert json_response(conn, 422)["errors"] == %{
               "amount_available" => ["can't be blank"],
               "cost" => ["can't be blank"],
               "product_name" => ["can't be blank"]
             }
    end

    test "renders errors when user is not seller", %{
      conn: conn
    } do
      user = AccountsFixtures.user_fixture(%{role: :buyer})
      user_token = ApiTokens.create_user_api_token(user)
      conn_with_token = put_req_header(conn, "authorization", "Bearer #{user_token}")

      conn =
        post(conn_with_token, ~p"/api/products",
          product_name: "some product_name",
          cost: 1,
          amount_available: 1
        )

      assert response(conn, 401) == "You must be a seller to access this resource."
    end

    test "renders product when data is valid", %{conn_with_token: conn, user: user} do
      %{
        product_name: product_name,
        cost: cost,
        amount_available: amount_available
      } = valid_product_attributes()

      conn =
        post(conn, ~p"/api/products",
          product_name: product_name,
          cost: cost,
          amount_available: amount_available
        )

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/products/#{id}")
      seller_id = user.id

      assert %{
               "id" => ^id,
               "product_name" => ^product_name,
               "cost" => ^cost,
               "amount_available" => ^amount_available,
               "seller_id" => ^seller_id
             } = json_response(conn, 200)["data"]
    end
  end

  describe "update product" do
    test "renders errors when user is not logged in", %{conn: conn, product: product} do
      conn =
        put(conn, ~p"/api/products/#{product}", product: valid_product_attributes())

      assert response(conn, 401) == "You must use a valid token to access this resource."
    end

    test "renders errors when user is not product seller", %{
      conn_with_token: conn,
      random_product: product
    } do
      conn =
        put(conn, ~p"/api/products/#{product}", product: valid_product_attributes())

      assert response(conn, 401) ==
               "You must be the seller of the product to access this resource."
    end

    test "renders errors when data is invalid", %{conn_with_token: conn, product: product} do
      conn =
        put(conn, ~p"/api/products/#{product}", cost: -1)

      assert json_response(conn, 422)["errors"] == %{
               "cost" => ["must be greater than 0"]
             }
    end

    test "renders product when data is valid", %{
      conn_with_token: conn,
      product: %Product{id: id} = product
    } do
      new_product_name = "some updated product_name"

      conn =
        put(conn, ~p"/api/products/#{product}", %{product_name: new_product_name})

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/products/#{id}")

      assert %{
               "id" => ^id,
               "product_name" => ^new_product_name
             } = json_response(conn, 200)["data"]
    end
  end

  describe "delete product" do
    test "renders errors when user is not logged in", %{conn: conn, product: product} do
      conn = delete(conn, ~p"/api/products/#{product}")

      assert response(conn, 401) == "You must use a valid token to access this resource."
    end

    test "renders errors when user is not product seller", %{
      conn_with_token: conn,
      random_product: product
    } do
      conn = delete(conn, ~p"/api/products/#{product}")

      assert response(conn, 401) ==
               "You must be the seller of the product to access this resource."
    end

    test "renders product when data is valid", %{conn_with_token: conn, product: product} do
      conn = delete(conn, ~p"/api/products/#{product}")

      assert response(conn, 204)

      new_conn = conn |> get(~p"/api/products/#{product}")
      assert response(new_conn, 404)
    end
  end
end
