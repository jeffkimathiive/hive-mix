defmodule Increaser.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Increaser.Worker.start_link(arg)
      {Increaser.Worker, :cats},
      {Increaser.Worker, :chickens},
      {Increaser.Worker, :cows},
      {Increaser.Worker, :dogs},
      {Increaser.Worker, :pigs}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :rest_for_one, name: Increaser.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
