defmodule MvpMatchCodeChallenge.Accounts.UserToken do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Query
  alias MvpMatchCodeChallenge.Accounts.UserToken

  @hash_algorithm :sha256
  @rand_size 32

  @session_validity_in_days 60
  @api_token_validity_in_days 90

  @session_token_context "session"
  @api_token_context "api-token"

  schema "users_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :user, MvpMatchCodeChallenge.Accounts.User

    timestamps(updated_at: false)
  end

  @doc """
  Generates a token that will be stored in a signed place,
  such as session or cookie. As they are signed, those
  tokens do not need to be hashed.

  The reason why we store session tokens in the database, even
  though Phoenix already provides a session cookie, is because
  Phoenix' default session cookies are not persisted, they are
  simply signed and potentially encrypted. This means they are
  valid indefinitely, unless you change the signing/encryption
  salt.

  Therefore, storing them allows individual user
  sessions to be expired. The token system can also be extended
  to store additional data, such as the device used for logging in.
  You could then use this information to display all valid sessions
  and devices in the UI and allow users to explicitly expire any
  session they deem invalid.
  """
  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %UserToken{token: token, context: @session_token_context, user_id: user.id}}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token, if any.

  The token is valid if it matches the value in the database and it has
  not expired (after @session_validity_in_days).
  """
  def verify_session_token_query(token) do
    query =
      from token in by_token_and_context_query(token, @session_token_context),
        join: user in assoc(token, :user),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: user

    {:ok, query}
  end

  @doc """
  Builds a token and its hash to be returned to the user.

  The non-hashed token is sent to the user while the
  hashed part is stored in the database. The original token cannot be reconstructed,
  which means anyone with read-only access to the database cannot directly use
  the token in the application to gain access. Furthermore, if the user changes
  their username in the system, the tokens sent to the previous username are no longer
  valid.
  """
  def build_api_token(user) do
    build_hashed_token(user, @api_token_context, user.username)
  end

  def verify_api_token_query(token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        days = @api_token_validity_in_days

        query =
          from token in by_token_and_context_query(hashed_token, @api_token_context),
            join: user in assoc(token, :user),
            where: token.inserted_at > ago(^days, "day") and token.sent_to == user.username,
            select: user

        {:ok, query}

      :error ->
        :error
    end
  end

  defp build_hashed_token(user, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %UserToken{
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       user_id: user.id
     }}
  end

  @doc """
  Returns the token struct for the given token value and context.
  """
  def by_token_and_context_query(token, context) do
    from UserToken, where: [token: ^token, context: ^context]
  end

  @doc """
  Gets all tokens for the given user for the given contexts.
  """
  def by_user_and_contexts_query(user, :all) do
    from t in UserToken, where: t.user_id == ^user.id
  end

  def by_user_and_contexts_query(user, [_ | _] = contexts) do
    from t in UserToken, where: t.user_id == ^user.id and t.context in ^contexts
  end

  @doc """
  Gets API and session valid tokens count for the given user.
  """
  def by_user_and_valid_tokens_count_query(user) do
    from t in UserToken,
      where: t.user_id == ^user.id,
      where:
        (t.context == ^@session_token_context and
           t.inserted_at > ago(^@session_validity_in_days, "day")) or
          (t.context == ^@api_token_context and
             t.inserted_at > ago(^@api_token_validity_in_days, "day")),
      group_by: t.context,
      select: {t.context, count(t.id)}
  end

  def get_session_validity_in_days(), do: @session_validity_in_days

  def get_session_token_context(), do: @session_token_context
  def get_api_token_context(), do: @api_token_context
end
