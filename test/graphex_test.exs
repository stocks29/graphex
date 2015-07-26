defmodule GraphexTest do
  use ExUnit.Case, async: true

  import Graphex
  alias Graphex.Dag

  test "graph() should return a graph" do
    fun = fn _ -> :ok end

    g = graph [
      [name: :a, fun: fun],
      [name: :b, fun: fun, deps: [:a]],
      [name: :c, fun: fun, deps: [:b]],
    ]

    vs = Dag.vertices(g)

    assert Enum.sort(vs) == [:a, :b, :c]
    assert Dag.upstreams(g, :a) == []
    assert Dag.upstreams(g, :b) == [:a]
    assert Dag.upstreams(g, :c) == [:b]

    Dag.delete(g)
  end

  test "graph() returns error if a dependency does not exist" do
    fun = fn _ -> :ok end

    ret = graph [
      [name: :a, fun: fun],
      [name: :b, fun: fun, deps: [:z]],
      [name: :c, fun: fun, deps: [:x]],
    ]

    assert ret == {:error, "Dependencies do not exist: x, z"}
  end

  test "graph() can be constructed in any order" do
    fun = fn _ -> :ok end

    g = graph [
      [name: :c, fun: fun, deps: [:b]],
      [name: :b, fun: fun, deps: [:a]],
      [name: :a, fun: fun],
    ]

    vs = Dag.vertices(g)

    assert Enum.sort(vs) == [:a, :b, :c]
    assert Dag.upstreams(g, :a) == []
    assert Dag.upstreams(g, :b) == [:a]
    assert Dag.upstreams(g, :c) == [:b]
  end

  test "should return all results" do
    result = exec_graph  [
      [name: :a, fun: fn _ -> 0 end],
      [name: :b, fun: incr(:a), deps: [:a]],
      [name: :c, fun: incr(:b), deps: [:b]],
      [name: :d, fun: incr(:b), deps: [:b]],
      [name: :e, fun: incr(:c), deps: [:c]],
    ]

    assert result == %{a: 0, b: 1, c: 2, d: 2, e: 3}
  end

  test "should return graph result" do
    result = exec_graph :e, [
      [name: :a, fun: fn _ -> 0 end],
      [name: :b, fun: incr(:a), deps: [:a]],
      [name: :c, fun: incr(:b), deps: [:b]],
      [name: :d, fun: incr(:b), deps: [:b]],
      [name: :e, fun: incr(:c), deps: [:c]],
    ]

    assert result == 3
  end

  test "can compose webpage" do
    result = exec_graph :wrapper, [
      [name: :greeting, fun: fn _ -> "Hi" end],
      [name: :user, fun: fn _ -> "Joe" end],
      [name: :message, fun: fn r -> "#{r[:greeting]} #{r[:user]}" end, deps: [:greeting, :user]],
      [name: :content, fun: fn r -> "<h1>#{r[:message]}</h1>" end, deps: [:message]],
      [name: :wrapper, fun: fn r -> "<html><head></head><body>#{r[:content]}</body></html>" end, deps: [:content]],
    ]
    assert result == "<html><head></head><body><h1>Hi Joe</h1></body></html>"
  end

  defp incr(node) do
    fn r ->
      r[node] + 1
    end
  end
end
