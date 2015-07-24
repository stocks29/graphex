defmodule Graphex.DagTest do
  use ExUnit.Case, async: true

  alias Graphex.Dag

  test "should return downstreams" do
    fun = fn _ -> 0 end

    dag = Dag.new()
    |> Dag.add_vertex(name: :a, deps: [], fun: fun)
    |> Dag.add_vertex(name: :b, deps: [:a], fun: fun)
    |> Dag.add_vertex(name: :c, deps: [:b], fun: fun)

    assert Dag.downstreams(dag, :b) == [:c]
  end
end
