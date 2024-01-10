defmodule MvpMatchCodeChallenge.Repo do
  use Ecto.Repo,
    otp_app: :mvp_match_code_challenge,
    adapter: Ecto.Adapters.Postgres
end
