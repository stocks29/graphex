defmodule Graphex.Execute.ParallelExecuteTest do
  use ExUnit.Case, async: true
  require Logger

  alias Graphex.Execute.ParallelExecute, as: E
  alias Graphex.Dag

  test "graph executed in proper order" do
    # given
    dag = test_graph_order()
    expected = %{a: 0, b: 1, c: 1, d: 1, e: 2, f: 3}

    # when/then
    assert E.exec_bf(dag) == expected

    # cleanup
    Dag.delete(dag)
  end

  test "dependency node restarted when it dies and graph executes" do
    {:ok, agent} = Agent.start_link fn -> [:boom, 1] end
    fun = fn _ ->
      Agent.get_and_update(agent,  fn [h|t] -> {h, t} end) + 1
    end

    # given
    dag = Dag.new()
    |> Dag.add_vertex_and_edges(name: :flaky, fun: fun, deps: [], tries: 2)
    |> Dag.add_vertex_and_edges(name: :b, fun: incr_dep(:flaky), deps: [:flaky])

    expected = %{flaky: 2, b: 3}

    # when/then
    assert E.exec_bf(dag) == expected

    # cleanup
    Dag.delete(dag)
    Agent.stop(agent)
  end

  test "dependency node not retried wth default tries (1) and deps receive error tuple" do
    # given
    dag = Dag.new()
    |> Dag.add_vertex_and_edges(name: :a, fun: fn _ -> :test end, deps: [])
    |> Dag.add_vertex_and_edges(name: :b, fun: fn r -> 1 + r[:a] end, deps: [:a])
    |> Dag.add_vertex_and_edges(name: :c, fun: fn r -> r[:b] end, deps: [:b])

    # when/then
    assert %{a: :test, b: {:error, {:graphex, error}}, c: {:error, {:graphex, error}}} = E.exec_bf(dag)

    # cleanup
    Dag.delete(dag)
  end

  test "dependent node restarted when it dies and graph executes" do
    {:ok, agent} = Agent.start_link fn -> [:boom, 4] end
    fun = fn r ->
      Agent.get_and_update(agent, fn [h|t] -> {h, t} end) + r[:a]
    end

    # given
    dag = Dag.new()
    |> Dag.add_vertex_and_edges(name: :a, fun: fn _ -> 1 end, deps: [])
    |> Dag.add_vertex_and_edges(name: :b, fun: fun, deps: [:a], tries: 2)

    expected = %{a: 1, b: 5}

    # when/then
    assert E.exec_bf(dag) == expected

    # cleanup
    Dag.delete(dag)
    Agent.stop(agent)
  end

  test "each node waits for its deps" do
    # given
    dag = test_graph_deps()

    # when
    results = E.exec_bf(dag)

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
    Dag.delete(dag)
  end

  test "only deps are passed to vertex function" do
    # given
    dag = test_graph_deps()
    expected = %{a: [], b: [:a], c: [:a], d: [:a], e: [:b, :c, :d], f: [:a, :e]}

    # when/then
    assert E.exec_bf(dag) == expected

    # cleanup
    Dag.delete(dag)
  end


  def incr_dep(dep) do
    fn results ->
      Map.get(results, dep) + 1
    end
  end

  def test_graph_deps do
    fun = fn results -> Map.keys(results)  end

    Dag.new()
    |> Dag.add_vertex_and_edges(name: :a, fun: fun, deps: [])
    |> Dag.add_vertex_and_edges(name: :b, fun: fun, deps: [:a])
    |> Dag.add_vertex_and_edges(name: :c, fun: fun, deps: [:a])
    |> Dag.add_vertex_and_edges(name: :d, fun: fun, deps: [:a])
    |> Dag.add_vertex_and_edges(name: :e, fun: fun, deps: [:b, :c, :d])
    |> Dag.add_vertex_and_edges(name: :f, fun: fun, deps: [:a, :e])
  end

  def test_graph_order do
    Dag.new()
    |> Dag.add_vertex_and_edges(name: :a, fun: fn _ -> 0 end, deps: [])
    |> Dag.add_vertex_and_edges(name: :b, fun: incr_dep(:a), deps: [:a])
    |> Dag.add_vertex_and_edges(name: :c, fun: incr_dep(:a), deps: [:a])
    |> Dag.add_vertex_and_edges(name: :d, fun: incr_dep(:a), deps: [:a])
    |> Dag.add_vertex_and_edges(name: :e, fun: incr_dep(:b), deps: [:b, :c, :d])
    |> Dag.add_vertex_and_edges(name: :f, fun: incr_dep(:e), deps: [:a, :e])
  end

end
