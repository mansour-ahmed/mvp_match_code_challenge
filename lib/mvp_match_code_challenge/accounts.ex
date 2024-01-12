defmodule MvpMatchCodeChallenge.Accounts do
  @moduledoc """
  The Accounts context for managing user operations.
  Handles user registration, authentication, and session management.
  """

  import Ecto.Query, warn: false
  alias MvpMatchCodeChallenge.Repo
  alias MvpMatchCodeChallenge.Accounts.{User, UserToken}

  ## Database getters

  @doc """
  Gets a user by their username.
  """
  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
  end

  @doc """
  Gets a user by their username and password. Returns `nil` if either
  the user is not found or the password does not match.
  """
  def get_user_by_username_and_password(username, password)
      when is_binary(username) and is_binary(password) do
    user = Repo.get_by(User, username: username)
    if user && User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user by their ID. Returns `nil` if the user does not exist.
  """
  def get_user(id), do: Repo.get(User, id)

  ## User registration

  @doc """
  Registers a new user with the provided attributes. Returns the user struct
  on successful registration or an Ecto.Changeset struct in case of an error.
  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_username: false)
  end

  def update_user_deposit(%User{} = user, attrs) do
    user
    |> User.deposit_changeset(attrs)
    |> Repo.update()
  end

  ## User settings

  @doc """
  Prepares a changeset for changing the user's password.
  By default, does not hash the new password.
  """
  def change_user_password(%User{} = user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user's password after verifying the current password.
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
  Deletes the specified user and all their associated tokens.
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

  ## Session management

  @doc """
  Generates a session token for the given user.
  """
  def generate_user_session_token(user) do
    {encoded_token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    encoded_token
  end

  @doc """
  Gets the user associated with a given session token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes a user's session token based on the given token value.
  """
  def delete_user_session_token(token) do
    token
    |> UserToken.by_token_and_context_query(UserToken.get_session_token_context())
    |> Repo.delete_all()

    :ok
  end
end
