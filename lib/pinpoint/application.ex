defmodule Pinpoint.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PinpointWeb.Telemetry,
      # Start the Ecto repository
      Pinpoint.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Pinpoint.PubSub},
      # Start Finch
      {Finch, name: Pinpoint.Finch},
      # Start the Endpoint (http/https)
      PinpointWeb.Endpoint
      # Start a worker by calling: Pinpoint.Worker.start_link(arg)
      # {Pinpoint.Worker, arg},
    ]

    :syn.set_event_handler(SynEventHandler)
    :syn.add_node_to_scopes([Pinpoint.OnlineUsers])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pinpoint.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PinpointWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
