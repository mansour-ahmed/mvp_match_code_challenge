defmodule MvpMatchCodeChallengeWeb.UserJSON do
  alias MvpMatchCodeChallenge.Accounts.User

  @doc """
  Renders a single user.
  """
  def show(%{user: user}) do
    %{data: data(user)}
  end

  defp data(%User{} = user) do
    %{
      id: user.id,
      username: user.username,
      role: user.role,
      deposit: user.deposit
    }
  end
end
