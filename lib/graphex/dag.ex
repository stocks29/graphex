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
end
