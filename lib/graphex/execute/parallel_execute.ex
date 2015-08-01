defmodule Graphex.Execute.ParallelExecute do
  require Logger

  alias Graphex.Dag
  alias Graphex.GraphSupervisor
  alias Graphex.VertexServer

  def exec_bf(dag) do
    {:ok, sup} = Graphex.Supervisor.start_graph_supervisor
    procs = init_processes(dag, sup)
    send_go_messages(procs, dag, self())
    result = accumulate_results(dag)
    :ok = Graphex.Supervisor.stop_graph_supervisor sup
    result
  end

  defp accumulate_results(dag) do
    Logger.debug("waiting for results")
    Enum.reduce(Dag.vertices(dag), %{}, fn _v, acc ->
      receive do
        {:result, name, result} ->
          Logger.debug("accumulator received result from #{inspect name}: #{inspect result}")
          Map.put(acc, name, result)
      end
    end)
  end

  defp send_go_messages(procs, dag, acc_pid) do
    Enum.each(procs, fn {name, pid} ->
      ds_verts = Dag.downstreams(dag, name)
      Logger.debug("#{name} has downstreams: #{inspect ds_verts}")

      ds_procs = procs
      |> Dict.take(ds_verts)
      |> Dict.values

      send_procs = [acc_pid|ds_procs]

      Logger.debug("sending go message to #{name}: #{inspect send_procs}")
      VertexServer.go pid, send_procs
    end)
  end

  defp init_processes(dag, sup) do
    for v <- Dag.vertices(dag) do
      {v, label} = Dag.vertex(dag, v)
      {v, spawn_node(v, label[:deps], label[:fun], sup)}
    end
  end

  defp spawn_node(name, deps, fun, sup) do
    {:ok, pid} = GraphSupervisor.start_vertex(sup, name, deps, fun)
    pid
  end

end
