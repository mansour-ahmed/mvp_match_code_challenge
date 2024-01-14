defmodule MvpMatchCodeChallengeWeb.ApiAuthTest do
  use MvpMatchCodeChallengeWeb.ConnCase, async: true

  alias MvpMatchCodeChallenge.{Accounts, ApiTokens}
  alias MvpMatchCodeChallengeWeb.ApiAuth
  import MvpMatchCodeChallenge.AccountsFixtures

  setup %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{})

    %{user: user_fixture(), conn: conn}
  end

  describe "fetch_api_user/2" do
    test "authenticates user from api token", %{conn: conn, user: user} do
      api_token = ApiTokens.create_user_api_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{api_token}")
        |> ApiAuth.fetch_api_user([])

      assert conn.assigns.current_user.id == user.id
    end

    test "does not authenticate if data is missing", %{conn: conn, user: user} do
      _ = Accounts.generate_user_session_token(user)
      conn = ApiAuth.fetch_api_user(conn, [])
      refute get_session(conn, :user_token)
      refute conn.assigns.current_user
    end
  end

  describe "api_require_authenticated_user/2" do
    test "responds with 401 if user is not authenticated", %{conn: conn} do
      conn =
        conn
        |> fetch_flash()
        |> ApiAuth.api_require_authenticated_user([])

      assert conn.halted
      assert conn.status == 401
      assert conn.resp_body == "You must use a valid token to access this resource."
    end

    test "does not respond with 401 if user is authenticated", %{conn: conn, user: user} do
      conn =
        conn
        |> assign(:current_user, user)
        |> ApiAuth.api_require_authenticated_user([])

      refute conn.halted
      refute conn.status
    end
  end

  describe "api_require_buyer_user/2" do
    test "responds with 403 if user is not buyer", %{conn: conn} do
      seller = user_fixture(%{role: :seller})

      conn =
        conn
        |> assign(:current_user, seller)
        |> fetch_flash()
        |> ApiAuth.api_require_buyer_user([])

      assert conn.halted
      assert conn.status == 403
      assert conn.resp_body == "You must be a buyer to access this resource."
    end

    test "does not respond with 401 if user is buyer", %{conn: conn} do
      buyer = user_fixture(%{role: :buyer})

      conn =
        conn
        |> assign(:current_user, buyer)
        |> ApiAuth.api_require_buyer_user([])

      refute conn.halted
      refute conn.status
    end
  end

  describe "api_require_seller_user/2" do
    test "responds with 403 if user is not seller", %{conn: conn} do
      buyer = user_fixture(%{role: :buyer})

      conn =
        conn
        |> assign(:current_user, buyer)
        |> fetch_flash()
        |> ApiAuth.api_require_seller_user([])

      assert conn.halted
      assert conn.status == 403
      assert conn.resp_body == "You must be a seller to access this resource."
    end

    test "does not respond with 401 if user is seller", %{conn: conn} do
      buyer = user_fixture(%{role: :seller})

      conn =
        conn
        |> assign(:current_user, buyer)
        |> ApiAuth.api_require_seller_user([])

      refute conn.halted
      refute conn.status
    end
  end

  describe "api_require_user_admin/2" do
    test "responds with 401 if user is not authenticated", %{conn: conn, user: user} do
      params = %{"id" => user.id}

      conn =
        %{conn | params: params}
        |> fetch_flash()
        |> ApiAuth.api_require_user_admin([])

      assert conn.halted
      assert conn.status == 401
      assert conn.resp_body == "You must use a valid token to access this resource."
    end

    test "responds with 403 if user is not admin", %{conn: conn, user: user} do
      random_user = user_fixture(%{role: :seller})
      params = %{"id" => random_user.id}

      conn =
        %{conn | params: params}
        |> assign(:current_user, user)
        |> fetch_flash()
        |> ApiAuth.api_require_user_admin([])

      assert conn.halted
      assert conn.status == 403
      assert conn.resp_body == "Not authorized"
    end

    test "responds with 403 if user id is not valid", %{conn: conn, user: user} do
      params = %{"id" => "foo"}

      conn =
        %{conn | params: params}
        |> assign(:current_user, user)
        |> fetch_flash()
        |> ApiAuth.api_require_user_admin([])

      assert conn.halted
      assert conn.status == 403
      assert conn.resp_body == "Not authorized"
    end

    test "does not respond with 401 if user is admin", %{conn: conn, user: user} do
      params = %{"id" => user.id}

      conn =
        %{conn | params: params}
        |> assign(:current_user, user)
        |> ApiAuth.api_require_user_admin([])

      refute conn.halted
      refute conn.status
    end
  end
end
