defmodule Graphex.DagTest do
  use ExUnit.Case, async: true

  alias Graphex.Dag

  test "should return downstreams" do
    fun = fn _ -> 0 end

    dag = Dag.new()
    |> Dag.add_vertex_and_edges(name: :a, deps: [], fun: fun)
    |> Dag.add_vertex_and_edges(name: :b, deps: [:a], fun: fun)
    |> Dag.add_vertex_and_edges(name: :c, deps: [:b], fun: fun)

    assert Dag.downstreams(dag, :a) == [:b]
    assert Dag.downstreams(dag, :b) == [:c]
    assert Dag.downstreams(dag, :c) == []

    Dag.delete(dag)
  end

  test "should return upstreams" do
    fun = fn _ -> 0 end

    dag = Dag.new()
    |> Dag.add_vertex_and_edges(name: :a, deps: [], fun: fun)
    |> Dag.add_vertex_and_edges(name: :b, deps: [:a], fun: fun)
    |> Dag.add_vertex_and_edges(name: :c, deps: [:b], fun: fun)

    assert Dag.upstreams(dag, :a) == []
    assert Dag.upstreams(dag, :b) == [:a]
    assert Dag.upstreams(dag, :c) == [:b]

    Dag.delete(dag)
  end

  test "can add a vertex with no deps" do
    fun = fn _ -> 0 end

    dag = Dag.new()
    |> Dag.add_vertex_and_edges(name: :a, fun: fun)

    Dag.delete(dag)
  end
end
