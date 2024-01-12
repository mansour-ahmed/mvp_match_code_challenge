defmodule MvpMatchCodeChallenge.ApiTokens do
  alias MvpMatchCodeChallenge.Repo
  alias MvpMatchCodeChallenge.Accounts.{UserToken, User}

  @doc """
  Deletes all tokens for the given user.
  """
  def delete_all_user_tokens(user) do
    user
    |> UserToken.by_user_and_contexts_query(:all)
    |> Repo.delete_all()

    :ok
  end

  @doc """
  Gets the count of active API and session tokens for a given user.
  """
  def get_user_active_tokens_count(user) do
    user
    |> UserToken.by_user_and_valid_tokens_count_query()
    |> Repo.all()
    |> count_tokens()
  end

  defp count_tokens(results) do
    session_token_context = UserToken.get_session_token_context()

    api_token_context =
      UserToken.get_api_token_context()

    default_count = %{session_token_count: 0, api_token_count: 0}

    Enum.reduce(results, default_count, fn
      {context, count}, acc ->
        case context do
          ^session_token_context -> Map.put(acc, :session_token_count, count)
          ^api_token_context -> Map.put(acc, :api_token_count, count)
        end
    end)
  end

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
