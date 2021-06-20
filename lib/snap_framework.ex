defmodule SnapFramework do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    RingLogger.attach
    # load the viewport configuration from config
    # main_viewport_config = Application.get_env(:snap_framework, :viewport)

    # start the application with the viewport
    # children = [
    #   {Scenic, viewports: []}
    # ]

    # Supervisor.start_link(children, strategy: :one_for_one)
  end
end
