defmodule MvpMatchCodeChallengeWeb.UserSessionControllerTest do
  use MvpMatchCodeChallengeWeb.ConnCase, async: true

  import MvpMatchCodeChallenge.AccountsFixtures
  alias MvpMatchCodeChallenge.ApiTokens

  setup do
    %{user: user_fixture()}
  end

  describe "POST /users/log_in" do
    test "logs the user in", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{"username" => user.username, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ user.username
      assert response =~ ~p"/users/settings"
      assert response =~ ~p"/users/log_out"
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{
            "username" => user.username,
            "password" => valid_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_mvp_match_code_challenge_web_user_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the user in with return to", %{conn: conn, user: user} do
      conn =
        conn
        |> init_test_session(user_return_to: "/foo/bar")
        |> post(~p"/users/log_in", %{
          "user" => %{
            "username" => user.username,
            "password" => valid_user_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, user: user} do
      conn =
        conn
        |> post(~p"/users/log_in", %{
          "_action" => "registered",
          "user" => %{
            "username" => user.username,
            "password" => valid_user_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, user: user} do
      conn =
        conn
        |> post(~p"/users/log_in", %{
          "_action" => "password_updated",
          "user" => %{
            "username" => user.username,
            "password" => valid_user_password()
          }
        })

      assert redirected_to(conn) == ~p"/users/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{"username" => "invalid_username", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid username or password"
      assert redirected_to(conn) == ~p"/users/log_in"
    end
  end

  describe "POST /api/users/token" do
    test "returns 400 when no correct params are sent", %{conn: conn} do
      conn = post(conn, ~p"/api/users/token", %{})
      assert json_response(conn, 400)["errors"] == %{"detail" => "Bad Request"}
    end

    test "returns 401 when credentials are incorrect", %{conn: conn} do
      conn =
        post(conn, ~p"/api/users/token", %{
          "user" => %{"username" => "invalid_username", "password" => "invalid_password"}
        })

      assert response(conn, 401) == "Invalid username or password"
    end

    test "returns user token when credentials are valid", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/api/users/token", %{
          "user" => %{"username" => user.username, "password" => valid_user_password()}
        })

      assert %{
               "tokens_count" =>
                 "You have 1 active API tokens and 0 web sessions. You can log out of all sessions by visiting api/users/log_out/all"
             } = json_response(conn, 200)["data"]
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> delete(~p"/users/log_out")

      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/users/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end

  describe "DELETE api/users/log_out/all" do
    setup %{
      conn: conn
    } do
      user = user_fixture(%{role: :buyer, deposit: 100})
      user_token = ApiTokens.create_user_api_token(user)

      conn_with_token = put_req_header(conn, "authorization", "Bearer #{user_token}")

      %{
        conn: conn,
        conn_with_token: conn_with_token
      }
    end

    test "returns 401 when user is not logged in", %{conn: conn} do
      conn = delete(conn, "/api/users/log_out/all")

      assert response(conn, 401) == "You must use a valid token to access this resource."
    end
  end
end
