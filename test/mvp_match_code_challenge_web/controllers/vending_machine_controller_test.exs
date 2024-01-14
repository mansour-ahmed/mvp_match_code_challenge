defmodule MvpMatchCodeChallengeWeb.VendingMachineControllerTest do
  use MvpMatchCodeChallengeWeb.ConnCase, async: true

  import MvpMatchCodeChallenge.ProductsFixtures
  import MvpMatchCodeChallenge.AccountsFixtures
  alias MvpMatchCodeChallenge.ApiTokens

  setup %{
    conn: conn
  } do
    user = user_fixture(%{role: :buyer, deposit: 100})
    user_token = ApiTokens.create_user_api_token(user)
    product = product_fixture(%{amount_available: 5, cost: 10})
    conn_with_token = put_req_header(conn, "authorization", "Bearer #{user_token}")

    %{
      conn: conn,
      user: user,
      product: product,
      user_token: user_token,
      conn_with_token: conn_with_token
    }
  end

  describe "POST /products/:id" do
    test "renders errors when user is not logged in", %{conn: conn, product: product} do
      conn =
        post(conn, ~p"/api/products/#{product.id}/buy", %{
          transaction_product_amount: 1
        })

      assert response(conn, 401) == "You must use a valid token to access this resource."
    end

    test "renders errors when product is not found", %{conn_with_token: conn} do
      conn =
        post(conn, ~p"/api/products/-1/buy", %{
          transaction_product_amount: 1
        })

      assert json_response(conn, 404)["errors"] == %{"detail" => "Not Found"}
    end

    test "renders errors when product id is not valid", %{conn_with_token: conn} do
      conn =
        post(conn, ~p"/api/products/foo/buy", %{
          transaction_product_amount: 1
        })

      assert json_response(conn, 400)["errors"] == %{"detail" => "Bad Request"}
    end

    test "renders error when buyer tries to buy more than available", %{
      conn_with_token: conn,
      product: product
    } do
      conn =
        post(conn, ~p"/api/products/#{product.id}/buy", %{
          transaction_product_amount: 10
        })

      assert %{
               "transaction_product_amount" => [
                 "must have enough stock to cover given product amount"
               ]
             } == json_response(conn, 422)["errors"]
    end

    test "renders error when buyer tries to buy with insufficient funds", %{
      conn_with_token: conn
    } do
      product = product_fixture(%{amount_available: 5, cost: 100_000})

      conn =
        post(conn, ~p"/api/products/#{product.id}/buy", %{
          transaction_product_amount: 3
        })

      assert %{
               "transaction_product_amount" => [
                 "must have enough funds to buy product with given amount"
               ]
             } == json_response(conn, 422)["errors"]
    end

    test "allows only buyers to buy products", %{conn: conn, product: product} do
      user = user_fixture(%{role: :seller})
      user_token = ApiTokens.create_user_api_token(user)
      conn_with_token = put_req_header(conn, "authorization", "Bearer #{user_token}")

      conn =
        post(conn_with_token, ~p"/api/products/#{product.id}/buy", %{
          transaction_product_amount: 1
        })

      assert response(conn, 401) == "You must be a buyer to access this resource."
    end

    test "renders transaction when product is found", %{conn_with_token: conn, product: product} do
      conn =
        post(conn, ~p"/api/products/#{product.id}/buy", %{
          transaction_product_amount: 1
        })

      assert %{
               "product" => %{
                 "id" => product.id,
                 "product_name" => product.product_name,
                 "cost" => product.cost |> Decimal.to_string()
               },
               "total_cost_to_buyer" => 10,
               "change_after_transaction_in_coins" => [50, 20, 20]
             } == json_response(conn, 200)["data"]
    end
  end
end
