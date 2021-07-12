defmodule Examples do
  @moduledoc """
  Starter application using the Scenic framework.
  """
  require Logger

  def start(_type, _args) do
    RingLogger.attach()
    # load the viewport configuration from config
    main_viewport_config = Application.get_env(:examples, :viewport)
    Logger.debug(inspect(main_viewport_config))
    # start the application with the viewport
    children = [
      {Scenic, [main_viewport_config]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
