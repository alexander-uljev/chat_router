defmodule Chat.Router.Application do
  @moduledoc false
  require Logger
  use Application

  def start(_type, _args) do
    children = [
      Chat.Router.DynamicSupervisor,
      Chat.Router
    ]
    opts = [strategy: :one_for_all, name: Chat.Router.Supervisor]
    Logger.info("Starting Router.DynamicSupervisor on #{node()}")
    Supervisor.start_link(children, opts)
  end
end
