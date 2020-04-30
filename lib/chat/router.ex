defmodule Chat.Router do
  @moduledoc """
  A globally accessible storage of chat application process identifiers.
  """

  use Agent
  @ext_key :__external__

  @doc """
  Starts an Agent link through `DynamicSupervisor` and adds it to
  `Chat.Router.Registry`.
  """
  @spec start_link(GenServer.options()) :: Agent.on_start()

  def start_link(_opts) do
    DynamicSupervisor.start_child({:global, Chat.Router.DynamicSupervisor},
      Supervisor.child_spec(Agent, start:
        {Agent, :start_link,
          [(fn -> %{@ext_key => []} end), [name: {:global, node()}]]}))
  end

  @doc """
  Checks if the Router has been started(globally).
  """
  @spec up?(name :: atom()) :: boolean()

  def up?(name \\ node()) do
    name in :global.registered_names()
  end

  @doc """
  Registers application pid under given key.
  """
  @spec register(app :: atom(), pid :: pid()) :: :ok

  def register(app, pid) do
    Agent.get_and_update(dest(), fn (map) ->
      case Map.fetch(map, app) do
        {:ok, pids} ->
          if pid in pids,
          do: {:error, :already_registered},
          else: {{:ok, pid}, Map.put(map, app, [pid | pids])}
        :error   ->
          {{:ok, pid}, Map.put(map, app, [pid])}
      end
    end)
  end

  @doc """
  Registers external router that will be queried in all subsequent `map/0` and
  `map/1` calls.
  """
  @spec register_router(node :: node()) :: :ok

  def register_router(node) do
    Agent.get_and_update(dest(), fn (map) ->
      case Map.fetch(map, node) do
        {:ok, _} -> {:error, :already_registered}
        :error   -> {{:ok, node}, Map.update!(map, @ext_key, &([node | &1]))}
      end
    end)
  end

  @doc """
  Returns external routers list if there is any.
  """
  @spec external() :: nil | [node()]

  def external() do
    Agent.get(dest(), &(&1))[:__external__]
  end

  @doc """
  Returns a stored map of application process ids for local node. In case there
  is key that is a live node name, that node's router will be queried and it's
  map will be added to returning list. If no arguments passed, entire map will
  be returned.
  """
  @spec map(app :: nil | atom()) :: %{required(atom()) => [pid()]} | [pid()]

  def map(app \\ nil) do # TODO: performance?
    map = Agent.get(dest(), &(Map.to_list(&1)))
    nodes = map[@ext_key]

    cond do
      app != nil and map[app] == nil ->
        {:error, :app_not_found}
      app != nil and map[app] != nil ->
        if nodes != [] do
          {:ok, reduce_remote_map(nodes, map[app], app) |> show_map()}
        else
          {:ok, map[app]}
        end
      app == nil ->
        if nodes != [] do
          reduce_remote_map(nodes, map) |> show_map()
        else
          show_map()
        end
    end

  end

  @doc """
  Clears stored routing map at once.
  """
  @spec clear() :: :ok

  def clear do
    Agent.update(dest(), fn (_state) -> %{@ext_key => []} end)
  end

  # private

  @spec dest() :: {:global, node()}
  defp dest(), do: {:global, node()}

  @spec reduce_remote_map([node()], keyword(), Application.app()) :: keyword()
  defp reduce_remote_map(nodes, map, app \\ nil) do
    Enum.reduce(nodes, [], fn (node, acc) ->
      map = Agent.get({:global, node}, &(Map.to_list(&1)))
      map[app] || map
      |> Keyword.delete(@ext_key)
      |> merge_concat(acc)
    end)
    |> merge_concat(map)
  end

  @spec show_map(keyword()) :: keyword()
  defp show_map(map \\ nil) do
    if Keyword.keyword?(map), do: format_keyword(map),
    else: Agent.get(dest(), &format_map/1)
  end

  @spec format_keyword(keyword()) :: keyword()
  defp format_keyword(kw) do
    Keyword.delete(kw, @ext_key)
  end

  @spec format_map(map()) :: keyword()
  defp format_map(map) do
    Map.delete(map, @ext_key) |> Map.to_list()
  end

  @spec merge_concat(keyword(), keyword()) :: keyword()
  defp merge_concat(kw1, kw2) do
    Keyword.merge(kw1, kw2, fn (_key, val1, val2) -> val1 ++ val2 end)
  end

end
