defmodule MvpMatchCodeChallenge.AccountsTest do
  use MvpMatchCodeChallenge.DataCase, async: true

  alias MvpMatchCodeChallenge.Accounts

  import MvpMatchCodeChallenge.AccountsFixtures
  alias MvpMatchCodeChallenge.Accounts.{User, UserToken}

  describe "get_user_by_username/1" do
    test "does not return the user if the username does not exist" do
      refute Accounts.get_user_by_username("unknown")
    end

    test "returns the user if the username exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_username(user.username)
    end
  end

  describe "get_user_by_username_and_password/2" do
    test "does not return the user if the username does not exist" do
      refute Accounts.get_user_by_username_and_password("unknown", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture()
      refute Accounts.get_user_by_username_and_password(user.username, "invalid")
    end

    test "returns the user if the username and password are valid" do
      %{id: id} = user = user_fixture()

      assert %User{id: ^id} =
               Accounts.get_user_by_username_and_password(user.username, valid_user_password())
    end
  end

  describe "get_user/1" do
    test "returns nil if id is invalid" do
      assert Accounts.get_user(-1) == nil
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user(user.id)
    end
  end

  describe "register_user/1" do
    test "requires username and password to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{
               password: ["can't be blank"],
               username: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates username and password when given" do
      {:error, changeset} =
        Accounts.register_user(%{username: "not valid", password: "not valid"})

      assert %{
               username: ["must have no spaces"],
               password: [
                 "at least one digit or punctuation character",
                 "at least one upper case character",
                 "should be at least 12 character(s)"
               ]
             } = errors_on(changeset)
    end

    test "validates maximum values for username and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{username: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).username
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates username uniqueness" do
      %{username: username} = user_fixture()
      {:error, changeset} = Accounts.register_user(%{username: username})
      assert "has already been taken" in errors_on(changeset).username

      # Now try with the upper cased username too, to check that username case is ignored.
      {:error, changeset} = Accounts.register_user(%{username: String.upcase(username)})
      assert "has already been taken" in errors_on(changeset).username
    end

    test "validates role when given" do
      user = valid_user_attributes(%{role: :unknown})
      {:error, changeset} = Accounts.register_user(user)
      assert %{role: ["is invalid"]} = errors_on(changeset)
    end

    test "validates deposit when given" do
      user = valid_user_attributes(%{deposit: -1})
      {:error, changeset} = Accounts.register_user(user)
      assert %{deposit: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "registers users with a hashed password" do
      username = unique_user_username()
      {:ok, user} = Accounts.register_user(valid_user_attributes(username: username))
      assert user.username == username
      assert is_binary(user.hashed_password)
      assert is_nil(user.password)
      assert user.role == :seller
      assert user.deposit == 0
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%User{})
      assert changeset.required == [:role, :deposit, :password, :username]
    end

    test "allows fields to be set" do
      username = unique_user_username()
      password = valid_user_password()

      changeset =
        Accounts.change_user_registration(
          %User{},
          valid_user_attributes(username: username, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :username) == username
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "add_coin_to_user_deposit/2" do
    setup do
      %{user: user_fixture(%{role: :buyer})}
    end

    test "validates coin", %{user: user} do
      assert {:error, :invalid_coin} =
               Accounts.add_coin_to_user_deposit(user, 2)
    end

    test "validates whether user is buyer" do
      user = user_fixture(%{role: :seller})

      assert {:error, :not_implemented} =
               Accounts.add_coin_to_user_deposit(user, 5)
    end

    test "adds coin to user deposit", %{user: user} do
      coin = 5

      {:ok, updated_user} = Accounts.add_coin_to_user_deposit(user, coin)
      assert updated_user.deposit == user.deposit + coin
    end
  end

  describe "reset_user_deposit/1" do
    setup do
      %{user: user_fixture(%{role: :buyer, deposit: 110})}
    end

    test "validates whether user is buyer" do
      user = user_fixture(%{role: :seller})

      assert {:error, :not_implemented} =
               Accounts.reset_user_deposit(user)
    end

    test "resets user deposit", %{user: user} do
      assert user.deposit == 110
      {:ok, updated_user} = Accounts.reset_user_deposit(user)
      assert updated_user.deposit == 0
    end
  end

  describe "change_user_password/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      new_valid_password = unique_user_password()

      changeset =
        Accounts.change_user_password(%User{}, %{
          "password" => new_valid_password
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == new_valid_password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/3" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, valid_user_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: [
                 "at least one digit or punctuation character",
                 "at least one upper case character",
                 "should be at least 12 character(s)"
               ],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_user_password(user, valid_user_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, "invalid", %{password: valid_user_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{user: user} do
      new_valid_password = unique_user_password()

      {:ok, user} =
        Accounts.update_user_password(user, valid_user_password(), %{
          password: new_valid_password
        })

      assert is_nil(user.password)
      assert Accounts.get_user_by_username_and_password(user.username, new_valid_password)
    end

    test "deletes all tokens for the given user", %{user: user} do
      new_valid_password = unique_user_password()
      _ = Accounts.generate_user_session_token(user)

      {:ok, _} =
        Accounts.update_user_password(user, valid_user_password(), %{
          password: new_valid_password
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "delete_user/1" do
    setup do
      %{user: user_fixture()}
    end

    test "deletes the user", %{user: user} do
      assert Accounts.delete_user(user) == :ok
      refute Accounts.get_user(user.id)
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)
      assert Repo.get_by(UserToken, user_id: user.id)
      assert Accounts.delete_user(user) == :ok
      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "delete_all_user_tokens/1" do
    setup do
      user = user_fixture()
      Accounts.generate_user_session_token(user)
      Accounts.create_user_api_token(user)
      %{user: user}
    end

    test "deletes all tokens for the given user", %{user: user} do
      assert UserToken
             |> Repo.all(user_id: user.id)
             |> Enum.count() == 2

      assert Accounts.delete_all_user_tokens(user) == :ok
      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "get_user_active_tokens_count/2" do
    test "returns the number of active tokens for the given user" do
      user = user_fixture()

      assert Accounts.get_user_active_tokens_count(user) == %{
               session_token_count: 0,
               api_token_count: 0
             }

      Accounts.generate_user_session_token(user)

      assert Accounts.get_user_active_tokens_count(user) == %{
               session_token_count: 1,
               api_token_count: 0
             }

      Accounts.create_user_api_token(user)
      Accounts.create_user_api_token(user)

      assert Accounts.get_user_active_tokens_count(user) == %{
               session_token_count: 1,
               api_token_count: 2
             }

      {3, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      assert Accounts.get_user_active_tokens_count(user) == %{
               session_token_count: 0,
               api_token_count: 0
             }
    end
  end

  describe "create_user_api_token/1" do
    test "creates a token" do
      user = user_fixture()
      encoded_token = Accounts.create_user_api_token(user)

      {:ok, token} = Base.url_decode64(encoded_token, padding: false)

      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.context == "api-token"
      assert user_token.sent_to == user.username
      assert user_token.user_id == user.id
    end
  end

  describe "fetch_user_by_api_token/1" do
    setup do
      user = user_fixture()
      encoded_token = Accounts.create_user_api_token(user)
      %{user: user, encoded_token: encoded_token}
    end

    test "does not return user for invalid token" do
      assert Accounts.fetch_user_by_api_token("oops") == :error
    end

    test "does not return user for expired token" do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.fetch_user_by_api_token("oops") == :error
    end

    test "does not return user for token with outdated username", %{encoded_token: encoded_token} do
      {1, nil} = Repo.update_all(User, set: [username: "#{System.unique_integer()}"])
      assert Accounts.fetch_user_by_api_token(encoded_token) == :error
    end

    test "returns user by token", %{user: user, encoded_token: encoded_token} do
      assert {:ok, api_user} = Accounts.fetch_user_by_api_token(encoded_token)
      assert api_user.id == user.id
    end
  end
end
