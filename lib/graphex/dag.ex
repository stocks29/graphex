defmodule Graphex.Dag do

  @typedoc """
  Directed Acyclic Graph
  """
  @type dag :: :digraph.graph

  @typedoc """
  Vertex dependencies
  """
  @type deps :: [Graphex.vertex] | nil

  @doc """
  Create a new directed acyclic graph
  """
  @spec new() :: dag
  def new() do
    :digraph.new([:acyclic])
  end

  @doc """
  Get a list of verticies
  """
  @spec vertices(dag) :: [Graphex.vertex]
  def vertices(dag) do
    :digraph.vertices(dag)
  end

  @doc """
  Get the vertex and label
  """
  @spec vertex(dag, Graphex.vertex) :: {Graphex.vertex, %{}}
  def vertex(dag, vertex) do
    :digraph.vertex(dag, vertex)
  end

  @doc """
  Delete the dag
  """
  @spec delete(dag) :: boolean
  def delete(dag) do
    :digraph.delete(dag)
  end

  @doc """
  Get a list of out edges for the given dag and vertex
  """
  @spec out_edges(dag, Graphex.vertex) :: [Graphex.edge]
  def out_edges(dag, vertex) do
    :digraph.out_edges(dag, vertex)
  end

  @doc """
  This will add a vertex and edges for all it's dependencies.

  If the dependency has not yet been added to the graph, this function will
  silently not add it.

  It is safer to use `Graphex.graph(components)` as that function will return
  {:error, message} if dependencies are missing. It doesn't care about the
  order the components are specified in.
  """
  @spec add_vertex_and_edges(dag, Graphex.component) :: dag
  def add_vertex_and_edges(dag, opts) do
    add_vertex(dag, opts)
    add_edges(dag, opts[:name], opts[:deps])
    dag
  end

  @doc """
  Add a vertex to a dag
  """
  @spec add_vertex(dag, Graphex.component) :: dag
  def add_vertex(dag, opts) do
    add_vertex(dag, opts[:name], opts[:deps], opts[:fun])
  end

  @doc """
  Add a vertex to a dag
  """
  @spec add_vertex(dag, Graphex.vertex, deps, (%{} -> any())) :: dag
  def add_vertex(dag, name, nil, fun) do
    add_vertex(dag, name, [], fun)
  end
  def add_vertex(dag, name, deps, fun) do
    :digraph.add_vertex(dag, name, %{fun: fun, deps: deps})
    dag
  end

  @doc """
  Add edges to a dag
  """
  @spec add_edges(dag, Graphex.vertex, deps) :: :ok
  def add_edges(dag, name, nil) do
    add_edges(dag, name, [])
  end
  def add_edges(dag, name, deps) do
    for dep <- deps do
      :digraph.add_edge(dag, dep, name)
    end
    :ok
  end

  @doc """
  Get a list of out verticies for a given list of edges
  """
  @spec out_verticies(dag, [Graphex.edge]) :: [Graphex.vertex]
  def out_verticies(dag, edges) do
    for e <- edges do
      out_vertex dag, e
    end
  end

  @doc """
  Get the out vertex for a given edge
  """
  @spec out_vertex(dag, Graphex.edge) :: Graphex.vertex
  def out_vertex(dag, e) do
    {^e, _, v, _} = :digraph.edge(dag, e)
    v
  end

  @doc """
  Get the list of in-verticies for the given list of edges
  """
  @spec in_verticies(dag, [Graphex.edges]) :: [Graphex.vertex]
  def in_verticies(dag, edges) do
    for e <- edges do
      in_vertex dag, e
    end
  end

  @doc """
  Get the in-vertex for a given edge
  """
  @spec in_vertex(dag, Graphex.edge) :: Graphex.vertex
  def in_vertex(dag, e) do
    {^e, v, _, _} = :digraph.edge(dag, e)
    v
  end

  @doc """
  Get the list of verticies that have no dependencies
  """
  @spec start_verticies(dag) :: [Graphex.vertex]
  def start_verticies(dag) do
    for v <- vertices(dag),
      in_edges = :digraph.in_edges(dag, v),
      length(in_edges) == 0 do
        v
    end
  end

  @doc """
  Get a list of verticies that are downstream of a given vertex. That is,
  get the list of verticies that depend on the result of the given vertex.
  """
  @spec downstreams(dag, Graphex.vertex) :: [Graphex.vertex]
  def downstreams(dag, v) do
    out_neighbors(dag, v)
  end

  @doc """
  Get a list of all verticies that are "out neighbors"
  """
  @spec out_neighbors(dag, Graphex.vertex) :: [Graphex.vertex]
  def out_neighbors(dag, vertex) do
    :digraph.out_neighbours(dag, vertex)
  end

  @doc """
  Get the list of verticies that are upstream of the given vertex. That is,
  get the list of verticies that the given vertex depends on the result of.
  """
  @spec upstreams(dag, Graphex.vertex) :: [Graphex.vertex]
  def upstreams(dag, v) do
    in_neighbors(dag, v)
  end

  @doc """
  Get a list of all verticies that are "in neighbors"
  """
  @spec in_neighbors(dag, Graphex.vertex) :: [Graphex.vertex]
  def in_neighbors(dag, vertex) do
    :digraph.in_neighbours(dag, vertex)
  end

end
