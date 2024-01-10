import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :argon2_elixir, t_cost: 1, m_cost: 8

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :mvp_match_code_challenge, MvpMatchCodeChallenge.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "mvp_match_code_challenge_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mvp_match_code_challenge, MvpMatchCodeChallengeWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "poJfl69e9k4Qg2NrPPLTyINVYW9hNEls++Fgh6B4JlKq8OuuU5v3DxphQJEX7Un9",
  server: false

# In test we don't send emails.
config :mvp_match_code_challenge, MvpMatchCodeChallenge.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
