defmodule SpringConfig.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    SpringConfig.Loader.load()
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: SpringConfig.Worker.start_link(arg)
      # {SpringConfig.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SpringConfig.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
