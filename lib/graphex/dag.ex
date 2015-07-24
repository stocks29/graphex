defmodule Graphex.Dag do

  def new() do
    :digraph.new([:acyclic])
  end

  def add_vertex(didag, opts) do
    add_vert(didag, opts[:name], opts[:deps], opts[:fun])
    add_edges(didag, opts[:name], opts[:deps])
    didag
  end

  defp add_vert(didag, name, deps, fun) do
    :digraph.add_vertex(didag, name, %{fun: fun, deps: deps})
  end

  defp add_edges(didag, name, deps) do
    for dep <- deps do
      :digraph.add_edge(didag, name, dep)
    end
    :ok
  end

  def out_virts(dag, edges) do
    for e <- edges do
      out_virt dag, e
    end
  end

  def out_virt(dag, e) do
    {^e, _, v, _} = :digraph.edge(dag, e)
    v
  end

  def in_vertices(dag, edges) do
    for e <- edges do
      in_vertex dag, e
    end
  end

  def in_vertex(dag, e) do
    {^e, v, _, _} = :digraph.edge(dag, e)
    v
  end

  def start_vs(dag) do
    for v <- :digraph.vertices(dag),
      in_edges = :digraph.in_edges(dag, v),
      length(in_edges) == 0 do
        v
    end
  end

  def downstreams(dag, v) do
    edges = :digraph.in_edges(dag, v)
    in_vertices(dag, edges)
  end

end
