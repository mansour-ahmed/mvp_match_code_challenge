defmodule MvpMatchCodeChallenge.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MvpMatchCodeChallengeWeb.Telemetry,
      MvpMatchCodeChallenge.Repo,
      {DNSCluster,
       query: Application.get_env(:mvp_match_code_challenge, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MvpMatchCodeChallenge.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: MvpMatchCodeChallenge.Finch},
      # Start a worker by calling: MvpMatchCodeChallenge.Worker.start_link(arg)
      # {MvpMatchCodeChallenge.Worker, arg},
      # Start to serve requests, typically the last entry
      MvpMatchCodeChallengeWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MvpMatchCodeChallenge.Supervisor]
    supervisor = Supervisor.start_link(children, opts)

    if System.get_env("RUN_SEEDS") == "true", do: run_seeds()

    supervisor
  end

  defp run_seeds do
    Code.compile_file("/app/lib/mvp_match_code_challenge-0.1.0/priv/repo/seeds.exs")
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MvpMatchCodeChallengeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
