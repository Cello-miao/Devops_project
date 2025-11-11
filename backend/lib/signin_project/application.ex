defmodule SigninProject.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SigninProjectWeb.Telemetry,
      SigninProject.Repo,
      {DNSCluster, query: Application.get_env(:signin_project, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SigninProject.PubSub},
      # Start a worker by calling: SigninProject.Worker.start_link(arg)
      # {SigninProject.Worker, arg},
      # Start to serve requests, typically the last entry
      SigninProjectWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SigninProject.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SigninProjectWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
