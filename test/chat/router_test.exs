defmodule Chat.RouterTest do
  use ExUnit.Case
  alias Chat.Router

  setup_all  :fetch_remote_node
  setup      :clear_state

  test "gets a applications pid map" do
    assert Router.map() == []
  end

  test "registers an application's pid in a list" do
    {app, pid}  = {:good_app, spawn(fn -> [] end)}
    {:ok, _pid} = Router.register(app, pid)
    assert {:ok, [pid]} == Router.map(app)
  end

  test "registers other nodes under reserved key", %{remote_node: node} do
    {:ok, _} = Router.register_router(node)
    assert Router.external() == [node]
  end

  test "checks if router is up" do
    assert Router.up?
  end

  test "extends returned values in case external key presents",
  %{remote_node: node} do
    {app, pid} = {:good_app, spawn(fn -> [] end)}
    {:ok, _} = Router.register(app, pid)
    Node.spawn_link(node, Router, :register, [:cool_app, pid])
    {:ok, _} = Router.register_router(node)
    assert Router.map() == [cool_app: [pid], good_app: [pid]]
  end

  test "extends returned values for app in case external key presents",
  %{remote_node: node} do
    {app, pid} = {:fine_app, spawn(fn -> [] end)}
    {:ok, _} = Router.register(app, pid)
    Node.spawn_link(node, Router, :register, [app, pid])
    {:ok, _} = Router.register_router(node)
    assert Router.map() == [{app, [pid, pid]}]
  end

  test "clears stored map" do
    app = :good_app
    pid = spawn(fn -> [] end)
    Router.register(app, pid)
    Router.clear()
    assert Router.map() == []
  end


  defp fetch_remote_node(_) do
    %{remote_node: ExUnit.configuration()[:remote_node]}
  end

  defp clear_state(%{remote_node: node}) do
    Node.spawn_link(node, Router, :clear, [])
    Router.clear()
  end

end
