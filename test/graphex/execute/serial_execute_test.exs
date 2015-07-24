defmodule Graphex.Execute.SerialExecuteTest do
  use ExUnit.Case, async: true

  alias Graphex.Execute.SerialExecute, as: SE
  alias Graphex.Dag

  test "graph executed in proper order" do
    # given
    dag = test_graph_order()
    expected = %{a: 0, b: 1, c: 1, d: 1, e: 2, f: 3}

    # when/then
    assert SE.exec_bf(dag) == expected

    # cleanup
    :digraph.delete(dag)
  end

  test "each node waits for its deps" do
    # given
    dag = test_graph_deps()

    # when
    results = SE.exec_bf(dag)

    # then
    assert results[:a] == []

    assert Enum.member?(results[:b], :a)
    assert Enum.member?(results[:c], :a)
    assert Enum.member?(results[:d], :a)

    assert Enum.member?(results[:e], :b)
    assert Enum.member?(results[:e], :c)
    assert Enum.member?(results[:e], :d)

    assert Enum.member?(results[:f], :e)

    # cleanup
    :digraph.delete(dag)
  end

  test "only deps are passed to vertex function" do
    # given
    dag = test_graph_deps()
    expected = %{a: [], b: [:a], c: [:a], d: [:a], e: [:b, :c, :d], f: [:a, :e]}

    # when/then
    assert SE.exec_bf(dag) == expected

    # cleanup
    :digraph.delete(dag)
  end


  def incr_dep(dep) do
    fn results ->
      Map.get(results, dep) + 1
    end
  end

  def test_graph_deps do
    fun = fn results -> Map.keys(results)  end

    Dag.new()
    |> Dag.add_vertex(name: :a, fun: fun, deps: [])
    |> Dag.add_vertex(name: :b, fun: fun, deps: [:a])
    |> Dag.add_vertex(name: :c, fun: fun, deps: [:a])
    |> Dag.add_vertex(name: :d, fun: fun, deps: [:a])
    |> Dag.add_vertex(name: :e, fun: fun, deps: [:b, :c, :d])
    |> Dag.add_vertex(name: :f, fun: fun, deps: [:a, :e])
  end

  def test_graph_order do
    Dag.new()
    |> Dag.add_vertex(name: :a, fun: fn _ -> 0 end, deps: [])
    |> Dag.add_vertex(name: :b, fun: incr_dep(:a), deps: [:a])
    |> Dag.add_vertex(name: :c, fun: incr_dep(:a), deps: [:a])
    |> Dag.add_vertex(name: :d, fun: incr_dep(:a), deps: [:a])
    |> Dag.add_vertex(name: :e, fun: incr_dep(:b), deps: [:b, :c, :d])
    |> Dag.add_vertex(name: :f, fun: incr_dep(:e), deps: [:a, :e])
  end

end
