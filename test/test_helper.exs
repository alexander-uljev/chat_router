# {:ok, _} = Node.start(:"test0@alex.localdomain", :longnames)

ext_node = :"test1@127.0.0.1"
:global.unregister_name(Chat.Router.DynamicSupervisor)
Node.connect(ext_node)
Process.sleep(50)
# IO.inspect :global.registered_names
# IO.inspect Node.list
# {res, 0}
# node_launch = spawn(fn() ->
  # System.cmd("elixir", ["--sname", to_string(ext_node),
  #   "-S", "mix", "run", "--no-halt", "--", "&"],
  #     env: [{"MIX_TEST", "test"}])
# end)
# Task.await(node_launch)

# [pid] = Regex.run(~r/\d+$/, res)

ExUnit.start(remote_node: ext_node)

# Process.exit(pid, :terminate)
# System.cmd("kill", [pid])
# IO.puts("--DONE--")
