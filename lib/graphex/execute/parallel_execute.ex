defmodule Graphex.Execute.ParallelExecute do
  require Logger

  alias Graphex.Dag

  alias Graphex.Supervisor, as: GSupervisor
  alias Graphex.VertexSupervisor
  alias Graphex.ResultServer

  @doc """
  Execute the graph, breadth-first
  """
  def exec_bf(dag) do
    supervisor_result_server_txn(Dag.vertices(dag), fn supervisor, result_server ->
      start_processes(dag, supervisor, result_server)
      wait_for_results()
    end)
  end

  defp supervisor_result_server_txn(vertices, fun) do
    {:ok, result_server} = ResultServer.start_link(vertices, self())
    {:ok, supervisor} = GSupervisor.start_vertex_supervisor
    result = fun.(supervisor, result_server)
    :ok = GSupervisor.stop_vertex_supervisor supervisor
    :ok = ResultServer.stop result_server
    result
  end

  # Processes must be started after before all their deps
  defp start_processes(dag, supervisor, result_server) do
    start_processes(Dag.vertices(dag), %{}, dag, supervisor, result_server)
  end

  defp start_processes([], procs, _dag, _supervisor, _result_server) do
    procs
  end
  defp start_processes([v|vs], procs, dag, supervisor, result_server) do
    downstreams = Dag.downstreams(dag, v)
    downstream_procs = Map.values(Map.take(procs, downstreams))
    if length(downstreams) == length(downstream_procs) do
      # All deps satisfied
      {v, label} = Dag.vertex(dag, v)
      pid = spawn_node(v, label[:deps], label[:fun], [result_server|downstream_procs], result_server, label[:tries], supervisor)
      procs = Map.put(procs, v, pid)
      start_processes(vs, procs, dag, supervisor, result_server)
    else
      start_processes(vs ++ [v], procs, dag, supervisor, result_server)
    end
  end

  defp spawn_node(name, deps, fun, downstream_procs, result_server, tries, sup) do
    {:ok, pid} = VertexSupervisor.start_vertex(sup, name, deps, fun, downstream_procs, result_server, tries)
    pid
  end

  defp wait_for_results do
    Logger.debug("waiting for results")
    receive do
      {:results, results} ->
        Logger.debug("final results: #{inspect results}")
        results
    end
  end

end
