defmodule MvpMatchCodeChallengeWeb.UserControllerTest do
  use MvpMatchCodeChallengeWeb.ConnCase, async: true

  import MvpMatchCodeChallenge.AccountsFixtures
  alias MvpMatchCodeChallenge.ApiTokens

  setup %{
    conn: conn
  } do
    user = user_fixture(%{role: :buyer, deposit: 100})
    random_user = user_fixture(%{role: :buyer})
    user_token = ApiTokens.create_user_api_token(user)

    conn_with_token = put_req_header(conn, "authorization", "Bearer #{user_token}")

    %{
      conn: conn,
      user: user,
      random_user: random_user,
      user_token: user_token,
      conn_with_token: conn_with_token
    }
  end

  describe "GET /api/users/:id" do
    test "returns 401 when user is not logged in", %{conn: conn, user: user} do
      conn = get(conn, "/api/users/#{user.id}")

      assert response(conn, 401) == "You must use a valid token to access this resource."
    end

    test "returns 401 when user is not given user admin", %{
      conn_with_token: conn,
      random_user: random_user
    } do
      conn = get(conn, "/api/users/#{random_user.id}")

      assert response(conn, 401) == "Not authorized"
    end

    test "returns 401 when user is not found", %{conn_with_token: conn} do
      conn = get(conn, "/api/users/223232")

      assert response(conn, 401) == "Not authorized"
    end

    test "returns 200 when user is found", %{conn_with_token: conn, user: user} do
      conn = get(conn, "/api/users/#{user.id}")

      assert json_response(conn, 200)["data"] == user_json(user)
    end
  end

  describe "POST /api/users" do
    test "returns 400 when invalid params are used", %{conn: conn} do
      conn = post(conn, "/api/users", %{})

      assert json_response(conn, 400)["errors"] === %{"detail" => "Bad Request"}
    end

    test "returns 201 when valid params are used", %{conn: conn} do
      user_attrs = valid_user_attributes(%{deposit: 100, role: "buyer"})
      conn = post(conn, "/api/users", %{user: user_attrs})

      assert user = json_response(conn, 201)["data"]

      assert user["username"] == user_attrs.username
      assert user["deposit"] == user_attrs.deposit
      assert user["role"] == user_attrs.role
    end
  end

  describe "DELETE /api/users/:id" do
    test "returns 401 when user is not logged in", %{conn: conn, user: user} do
      conn = delete(conn, "/api/users/#{user.id}")

      assert response(conn, 401) == "You must use a valid token to access this resource."
    end

    test "returns 401 when user is not given user admin", %{
      conn_with_token: conn,
      random_user: random_user
    } do
      conn = delete(conn, "/api/users/#{random_user.id}")

      assert response(conn, 401) == "Not authorized"
    end

    test "returns 401 when user is not found", %{conn_with_token: conn} do
      conn = delete(conn, "/api/users/223232")

      assert response(conn, 401) == "Not authorized"
    end

    test "returns 204 when user is found", %{conn_with_token: conn, user: user} do
      conn = delete(conn, "/api/users/#{user.id}")

      assert response(conn, 204)
    end
  end

  describe "PUT /api/user/:id/deposit/reset" do
    test "returns 401 when user is not logged in", %{conn: conn, user: user} do
      conn = put(conn, "/api/users/#{user.id}/deposit/reset")

      assert response(conn, 401) == "You must use a valid token to access this resource."
    end

    test "returns 401 when user is not given user admin", %{
      conn_with_token: conn,
      random_user: random_user
    } do
      conn = put(conn, "/api/users/#{random_user.id}/deposit/reset")

      assert response(conn, 401) == "Not authorized"
    end

    test "returns 401 when user does not have buyer role", %{
      conn: conn
    } do
      seller_user = user_fixture(%{role: :seller})
      user_token = ApiTokens.create_user_api_token(seller_user)
      conn_with_token = put_req_header(conn, "authorization", "Bearer #{user_token}")

      conn = put(conn_with_token, "/api/users/#{seller_user.id}/deposit/reset")

      assert response(conn, 401) == "You must be a buyer to access this resource."
    end

    test "returns 401 when user is not found", %{conn_with_token: conn} do
      conn = put(conn, "/api/users/223232/deposit/reset")

      assert response(conn, 401) == "Not authorized"
    end

    test "returns 200 when user is found", %{conn_with_token: conn, user: user} do
      conn = put(conn, "/api/users/#{user.id}/deposit/reset")

      assert %{"deposit" => 0} = json_response(conn, 200)["data"]
    end
  end

  describe "POST /api/users/:id/deposit/:coin" do
    test "returns 401 when user is not logged in", %{conn: conn, user: user} do
      conn = post(conn, "/api/users/#{user.id}/deposit/5")

      assert response(conn, 401) == "You must use a valid token to access this resource."
    end

    test "returns 401 when user is not given user admin", %{
      conn_with_token: conn,
      random_user: random_user
    } do
      conn = post(conn, "/api/users/#{random_user.id}/deposit/5")

      assert response(conn, 401) == "Not authorized"
    end

    test "returns 401 when user does not have buyer role", %{
      conn: conn
    } do
      seller_user = user_fixture(%{role: :seller})
      user_token = ApiTokens.create_user_api_token(seller_user)
      conn_with_token = put_req_header(conn, "authorization", "Bearer #{user_token}")

      conn = post(conn_with_token, "/api/users/#{seller_user.id}/deposit/5")

      assert response(conn, 401) == "You must be a buyer to access this resource."
    end

    test "returns 401 when user is not found", %{conn_with_token: conn} do
      conn = post(conn, "/api/users/223232/deposit/5")

      assert response(conn, 401) == "Not authorized"
    end

    test "returns 200 when user is found", %{conn_with_token: conn, user: user} do
      conn = post(conn, "/api/users/#{user.id}/deposit/5")

      assert json_response(conn, 200)["data"]["deposit"] == 5 + user.deposit
    end

    test "returns 400 when invalid coin is used", %{conn_with_token: conn, user: user} do
      conn = post(conn, "/api/users/#{user.id}/deposit/2")

      assert json_response(conn, 400)["errors"] === %{
               "details" => "Invalid coin value. Only 5, 10, 20, 50, 100 coins are allowed."
             }
    end
  end
end
