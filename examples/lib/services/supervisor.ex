defmodule Examples.Services.Supervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(_) do
    children = [
      Examples.Services.MyService
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
