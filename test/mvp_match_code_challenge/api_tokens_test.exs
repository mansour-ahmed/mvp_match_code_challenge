defmodule MvpMatchCodeChallenge.ApiTokensTest do
  use MvpMatchCodeChallenge.DataCase, async: true

  import MvpMatchCodeChallenge.AccountsFixtures
  alias MvpMatchCodeChallenge.{ApiTokens, Accounts}
  alias MvpMatchCodeChallenge.Accounts.{User, UserToken}

  setup do
    user = user_fixture()
    %{user: user}
  end

  describe "delete_all_user_tokens/1" do
    setup %{user: user} do
      Accounts.generate_user_session_token(user)
      ApiTokens.create_user_api_token(user)
      %{user: user}
    end

    test "deletes all tokens for the given user", %{user: user} do
      assert UserToken
             |> Repo.all(user_id: user.id)
             |> Enum.count() == 2

      assert ApiTokens.delete_all_user_tokens(user) == :ok
      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "get_user_active_tokens_count/2" do
    test "returns the number of active tokens for the given user", %{user: user} do
      assert ApiTokens.get_user_active_tokens_count(user) == %{
               session_token_count: 0,
               api_token_count: 0
             }

      Accounts.generate_user_session_token(user)

      assert ApiTokens.get_user_active_tokens_count(user) == %{
               session_token_count: 1,
               api_token_count: 0
             }

      ApiTokens.create_user_api_token(user)
      ApiTokens.create_user_api_token(user)

      assert ApiTokens.get_user_active_tokens_count(user) == %{
               session_token_count: 1,
               api_token_count: 2
             }

      {3, nil} =
        Repo.update_all(UserToken,
          set: [inserted_at: DateTime.utc_now() |> DateTime.add(-365, :day)]
        )

      assert ApiTokens.get_user_active_tokens_count(user) == %{
               session_token_count: 0,
               api_token_count: 0
             }
    end
  end

  describe "create_user_api_token/1" do
    test "creates a token", %{user: user} do
      encoded_token = ApiTokens.create_user_api_token(user)

      {:ok, token} = Base.url_decode64(encoded_token, padding: false)

      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.context == "api-token"
      assert user_token.sent_to == user.username
      assert user_token.user_id == user.id
    end
  end

  describe "fetch_user_by_api_token/1" do
    setup %{user: user} do
      encoded_token = ApiTokens.create_user_api_token(user)
      %{encoded_token: encoded_token}
    end

    test "does not return user for invalid token" do
      assert ApiTokens.fetch_user_by_api_token("oops") == :error
    end

    test "does not return user for expired token" do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert ApiTokens.fetch_user_by_api_token("oops") == :error
    end

    test "does not return user for token with outdated username", %{encoded_token: encoded_token} do
      {1, nil} = Repo.update_all(User, set: [username: "#{System.unique_integer()}"])
      assert ApiTokens.fetch_user_by_api_token(encoded_token) == :error
    end

    test "returns user by token", %{user: user, encoded_token: encoded_token} do
      assert {:ok, api_user} = ApiTokens.fetch_user_by_api_token(encoded_token)
      assert api_user.id == user.id
    end
  end
end
