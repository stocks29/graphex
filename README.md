Graphex
=======

A library for composing and executing task graphs in elixir.

### Add as Dependency

```elixir
{:graphex, "~> 0.0.1"}
```

## Usage

Each node is represented by a separate process so tasks will run in parallel if possible.

```elixir
incr = fn node ->
  fn r -> r[node] + 1
end

result = exec_graph :e, [
  [name: :a, fun: fn _ -> 0 end],
  [name: :b, fun: incr.(:a), deps: [:a]],
  [name: :c, fun: incr.(:b), deps: [:b]],
  [name: :d, fun: incr.(:b), deps: [:b]],
  [name: :e, fun: incr.(:c), deps: [:c]],
]

assert result == 3
```
