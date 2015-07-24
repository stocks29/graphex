defmodule Graphex.Execute.ParallelExecute do
  require Logger

  alias Graphex.Dag

  def exec_bf(dag) do
    procs = init_processes(dag)
    send_go_messages(procs, dag, self())
    accumulate_results(dag)
  end

  defp accumulate_results(dag) do
    Logger.debug("waiting for results")
    Enum.reduce(:digraph.vertices(dag), %{}, fn _v, acc ->
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
      message = {:go, send_procs}

      Logger.debug("sending go message to #{name}: #{inspect message}")
      send pid, message
    end)
  end

  defp init_processes(dag) do
    for v <- :digraph.vertices(dag) do
      {v, label} = :digraph.vertex(dag, v)
      {v, spawn_node(v, label[:deps], label[:fun])}
    end
  end

  defp spawn_node(name, deps, fun) do
    spawn_link(fn ->
      node_loop(:waiting, name, deps, fun, %{})
    end)
  end



  ######
  # Node code
  ######

  defp node_loop(:waiting, name, deps, fun, results) do
    Logger.debug("#{inspect name} waiting for :go")
    receive do
      {:go, downstreams} ->
        Logger.debug("#{inspect name} received :go message")
        node_loop(:running, name, deps, downstreams, fun, results)
    end
  end

  defp node_loop(:running, name, [], downstreams, fun, results) do
    Logger.debug("#{inspect name} publishing results to downstreams")
    publish_result(name, fun.(results), downstreams)
  end
  defp node_loop(:running, name, deps, downstreams, fun, results) do
    receive do
      {:result, dep, result} ->
        Logger.debug("#{inspect name} received result from #{inspect dep}")
        node_loop(:running, name, List.delete(deps, dep), downstreams, fun, Map.put(results, dep, result))
      other ->
        Logger.warn("received unknown message: #{inspect other}")
    end
  end


  defp publish_result(name, result, downstreams) do
    Logger.debug "#{inspect name} publishing result: #{inspect result} to #{inspect downstreams}"
    Enum.each(downstreams, fn downstream ->
      send downstream, {:result, name, result}
    end)
  end

  #######
  # Result receiver loop
  #######

  # defp spawn_result_receiver() do
  #   spawn_link(fn ->
  #     result_receiver_loop(:waiting);
  #   end)
  # end
  #
  # defp result_receiver_loop(:holding, result) do
  #   receive do
  #     {:get, pid, result} -> send pid, result
  #   end
  # end
  # defp result_receiver_loop(:waiting) do
  #   receive do
  #     {:result, _dep, result} -> result
  #   end
  # end

end
