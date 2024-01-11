defmodule MvpMatchCodeChallenge.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MvpMatchCodeChallenge.Accounts` context.
  """

  def unique_user_username, do: "user#{System.unique_integer()}"
  def valid_user_password(), do: "MReakZzawL8.4L4PHL"
  def unique_user_password, do: "#{valid_user_password()}#{System.unique_integer()}"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      username: unique_user_username(),
      password: valid_user_password(),
      role: :seller
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> MvpMatchCodeChallenge.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_username} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_username.text_body, "[TOKEN]")
    token
  end

  def user_json(user) do
    %{
      "id" => user.id,
      "username" => user.username,
      "role" => user.role |> Atom.to_string(),
      "deposit" => user.deposit
    }
  end
end
