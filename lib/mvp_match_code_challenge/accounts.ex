defmodule MvpMatchCodeChallenge.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias MvpMatchCodeChallenge.VendingMachine
  alias MvpMatchCodeChallenge.Repo

  alias MvpMatchCodeChallenge.Accounts.{User, UserToken}

  ## Database getters

  @doc """
  Gets a user by username.

  ## Examples

      iex> get_user_by_username("foo123")
      %User{}

      iex> get_user_by_username("unknown")
      nil

  """
  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
  end

  @doc """
  Gets a user by username and password.

  ## Examples

      iex> get_user_by_username_and_password("foo123", "correct_password")
      %User{}

      iex> get_user_by_username_and_password("foo123", "invalid_password")
      nil

  """
  def get_user_by_username_and_password(username, password)
      when is_binary(username) and is_binary(password) do
    user = Repo.get_by(User, username: username)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Returns `nil` if the User does not exist.

   ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(456)
      nil
  """
  def get_user(id), do: Repo.get(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_username: false)
  end

  @doc """
  Adds given coin value to user deposit.
  Only permitted for users with the `:buyer` role.
  Only 5, 10, 20, 50, 100 coins are allowed.
  """
  def add_coin_to_user_deposit(%User{} = user, coin) when is_integer(coin) do
    if VendingMachine.coin_valid?(coin) do
      update_user_deposit(user, %{deposit: coin + user.deposit})
    else
      {:error, :invalid_coin}
    end
  end

  @doc """
  Resets the user deposit to zero.
  Only permitted for users with the `:buyer` role.
  """
  def reset_user_deposit(%User{} = user) do
    update_user_deposit(user, %{deposit: 0})
  end

  defp update_user_deposit(%User{} = user, attrs) do
    case user do
      %{role: :buyer} ->
        changeset = User.deposit_changeset(user, attrs)
        Repo.update(changeset)

      _ ->
        {:error, :not_implemented}
    end
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Deletes the given user and all its associated tokens.
  """
  def delete_user(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:user, user)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: _}} -> :ok
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {encoded_token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    encoded_token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## API

  @doc """
  Creates a new API token for the given user.

  The token returned must be saved somewhere safe.
  This token cannot be recovered from the database.
  """
  def create_user_api_token(user) do
    {encoded_token, user_token} = UserToken.build_api_token(user)
    Repo.insert!(user_token)
    encoded_token
  end

  @doc """
  Fetches the user by API token.
  """
  def fetch_user_by_api_token(token) do
    with {:ok, query} <- UserToken.verify_api_token_query(token),
         %User{} = user <- Repo.one(query) do
      {:ok, user}
    else
      _ -> :error
    end
  end
end
