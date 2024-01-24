defmodule SpotifyBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SpotifyBotWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:spotify_bot, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SpotifyBot.PubSub},
      # Start a worker by calling: SpotifyBot.Worker.start_link(arg)
      # {SpotifyBot.Worker, arg},
      # Start to serve requests, typically the last entry
      SpotifyBotWeb.Endpoint,
      {TwitchChat.Supervisor, Application.fetch_env!(:spotify_bot, :bot)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SpotifyBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SpotifyBotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
