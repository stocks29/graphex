defmodule Graphex.VertexServer do
  require Logger
  use GenServer

  alias Graphex.ResultServer

  ### Public API

  @doc """
  Start a vertex server
  """
  def start_link(name, deps, fun, downstream_procs, result_server, tries, opts \\ []) do
    GenServer.start_link(__MODULE__, [name, deps, fun, downstream_procs, result_server, tries], opts)
  end

  @doc """
  Tell the vertex server to check if all of the deps it's waiting for are
  complete, and if so, execute this step and publish the result.
  """
  def check_state(server) do
    GenServer.cast(server, :check_state)
  end


  ### Callbacks

  def init([name, deps, fun, downstreams, result_server, tries]) do
    Logger.debug "starting vertex server #{inspect self()} with name: #{inspect name}, deps: #{inspect deps}, fun: #{inspect fun}, result_server: #{inspect result_server}, tries: #{tries}"
    results = ResultServer.take(result_server, deps)
    Logger.debug "#{inspect name} loaded results from result server: #{inspect results}"
    deps = delete_items(deps, Map.keys(results))
    Logger.debug "#{inspect name} still waiting on deps #{inspect deps}"
    check_state self()
    {:ok, %{
      name: name,
      deps: deps,
      fun: fun,
      downstreams: downstreams,
      results: results,
      tries: tries,
      ref: nil,
    }}
  end

  def handle_cast(:check_state, %{name: name, deps: [], fun: fun, downstreams: downstreams, results: results, tries: tries} = state) do
    this = self()
    {pid,ref} = spawn_monitor(fn ->
      Logger.debug("monitored process executing node=#{inspect name} pid=#{inspect self()}")
      result = fun.(results)
      publish_result(name, result, [this|downstreams])
      Logger.debug("monitored process finished node=#{inspect name} pid=#{inspect self()}")
    end)
    Logger.debug("spawned monitored process to execute node #{inspect name} pid=#{inspect pid} ref=#{inspect ref}")
    {:noreply, %{state | :ref => ref, :tries => tries - 1}}
  end
  def handle_cast(:check_state, state) do
    # We must still have some deps we're waiting on results for
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, %{name: name, ref: ref, tries: tries, downstreams: downstreams} = state) when tries < 1 do
    Logger.warn "received :DOWN message and no more tries remaining for #{inspect name}: #{inspect reason}"
    publish_error(name, reason, downstreams)
    {:stop, :normal, state}
  end
  def handle_info({:DOWN, ref, :process, _pid, reason}, %{name: name, ref: ref} = state) do
    Logger.debug "#{inspect name} received :DOWN message from node's execution server: #{inspect reason}"
    check_state self()
    {:noreply, state}
  end
  def handle_info({:result, name, result}, %{name: name, results: results} = state) do
    Logger.debug "#{inspect name} received this node's result #{inspect result} from monitored process"
    new_results = Map.put(results, name, result)
    {:stop, :normal, Map.put(state, :results, new_results)}
  end
  def handle_info({:result, dep, result}, %{name: name, results: results, deps: deps} = state) do
    Logger.debug "#{inspect name} received result #{inspect result} from #{inspect dep}"
    check_state self()
    {:noreply, %{state |
      results: Map.put(results, dep, result),
      deps: List.delete(deps, dep)
    }}
  end


  ### Private Functions

  defp publish_error(name, error, downstreams) do
    publish_result(name, {:error, {:graphex, error}}, downstreams)
  end

  defp publish_result(name, result, downstreams) do
    Logger.debug "#{inspect name} publishing result: #{inspect result} to #{inspect downstreams}"
    Enum.each(downstreams, fn downstream ->
      send downstream, {:result, name, result}
    end)
  end

  defp delete_items(list, items) do
    Enum.reduce(items, list, fn item, acc ->
      List.delete(acc, item)
    end)
  end
end
