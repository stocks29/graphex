defmodule Graphex do

  alias Graphex.Dag
  alias Graphex.Execute.ParallelExecute, as: P

  @typedoc """
  A `component` is a keyword list with a `name`, `fun` and optionally `deps`.
  """
  @type component :: [Keyword]

  @typedoc """
  Identifier for a vertex
  """
  @type vertex :: :digraph.vertex

  @typedoc """
  Identifier for an edge
  """
  @type edge :: :digraph.edge

  @typedoc """
  `results` is a collection of results from executing a graph
  """
  @type results :: %{}

  @typedoc """
  `result_key` is a key used to retrieve an item from `results`.
  """
  @type result_key :: atom

  @typedoc """
  A graph
  """
  @type graph :: Graphex.Dag.dag


  @doc """
  Generate and execute a graph and return the results for the given `result_key`.

  The graph will be automatically deleted after execution.
  """
  @spec exec_graph(result_key, [component]) :: results
  def exec_graph(key, components) do
    results = exec_graph(components)
    results[key]
  end

  @doc """
  Generate and execute a graph and return the results for all vertexes.

  The graph will be automatically deleted after execution.
  """
  @spec exec_graph([component]) :: results
  def exec_graph(components) do
    dag = graph(components)
    results = P.exec_bf(dag)
    Dag.delete(dag)
    results
  end

  @doc """
  Generate a graph. Returns a new graph or `{:error, message}` if there is a
  problem constructing the graph.

  You will need to manually delete the graph after using it.
  """
  @spec graph([component]) :: graph
  def graph(components) do
    # construct dag and add vertexes
    {graph, verticies} = add_vertices(Dag.new, components)

    # Then add edges since we don't want the order of component statements to matter
    # without doing this, if the dep doesn't exist yet, the edge is silently not added
    add_edges(graph, components, Enum.into(verticies, HashSet.new()))
    |> graph_return()
  end

  @spec add_vertices(graph, [component]) :: {graph, [vertex]}
  defp add_vertices(graph, components) do
    Enum.reduce(components, {graph, []}, fn component, {acc, verticies} ->
      Dag.add_vertex(acc, component)
      {acc, [component[:name]|verticies]}
    end)
  end

  @spec add_edges(graph, [component], HashSet) :: {graph, [vertex]}
  defp add_edges(graph, components, name_set) do
    Enum.reduce(components, {graph, []}, fn component, {acc, missing_deps} ->
      deps = Dict.get(component, :deps, [])
      more_missing = Set.difference(Enum.into(deps, HashSet.new), name_set)
      Dag.add_edges(acc, component[:name], deps)
      {acc, Set.to_list(more_missing) ++ missing_deps}
    end)
  end

  @spec graph_return({graph, [Atom]}) :: graph | {:error, binary}
  defp graph_return({graph, []}), do: graph
  defp graph_return({_graph, missing_deps}) do
    {:error, "Dependencies do not exist: #{Enum.sort(missing_deps) |> Enum.join(", ")}"}
  end

end
