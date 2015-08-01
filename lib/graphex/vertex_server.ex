defmodule Graphex.VertexServer do
  require Logger
  use GenServer

  ### Public API

  def start_link(name, deps, fun, opts \\ []) do
    GenServer.start_link(__MODULE__, [name, deps, fun], opts)
  end

  def go(server, downstreams) do
    GenServer.cast(server, {:go, downstreams})
  end

  def check_state(server) do
    GenServer.cast(server, :check_state)
  end


  ### Callbacks

  def init([name, deps, fun]) do
    {:ok, %{
      state: :waiting,
      name: name,
      deps: deps,
      fun: fun,
      downstreams: [],
      results: %{}
    }}
  end

  def handle_cast({:go, downstreams}, %{state: :waiting} = state) do
    check_state self()
    {:noreply, %{state | state: :running, downstreams: downstreams}}
  end

  def handle_cast(:check_state, %{state: :running, name: name, deps: [], fun: fun, downstreams: downstreams, results: results} = state) do
    result = fun.(results)
    publish_result(name, result, downstreams)
    new_results = Map.put(results, name, result)
    {:stop, :normal, Map.put(state, :results, new_results)}
  end
  def handle_cast(:check_state, state) do
    # We must still have some deps we're waiting on results for
    {:noreply, state}
  end

  def handle_info({:result, dep, result}, %{results: results, deps: deps} = state) do
    check_state self()
    {:noreply, %{state |
      results: Map.put(results, dep, result),
      deps: List.delete(deps, dep)
    }}
  end



  ### Private Functions

  defp publish_result(name, result, downstreams) do
    Logger.debug "#{inspect name} publishing result: #{inspect result} to #{inspect downstreams}"
    Enum.each(downstreams, fn downstream ->
      send downstream, {:result, name, result}
    end)
  end
end
