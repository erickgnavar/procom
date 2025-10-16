defmodule Procom.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Procom.PromEx,
      ProcomWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:procom, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Procom.PubSub},
      # Start a worker by calling: Procom.Worker.start_link(arg)
      # {Procom.Worker, arg},
      # in memory products storage
      Procom.Workers.Storage,
      # Backup/restore products data
      Procom.Workers.Store,
      # Start to serve requests, typically the last entry
      ProcomWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Procom.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ProcomWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
