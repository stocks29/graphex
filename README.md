Graphex
=======

[![Build Status](https://travis-ci.org/stocks29/graphex.svg)](https://travis-ci.org/stocks29/graphex)

A library for composing and executing task graphs in elixir.

### Add as Dependency

```elixir
{:graphex, "~> 0.1.0"}
```

Also, be sure to add `:graphex` to your application's list of OTP applications since it has a supervision tree that must be started before using the library.

## Usage

Each node is represented by a separate process so tasks will run in parallel if possible. Failed nodes will be retried automatically per the default supervision restart settings.

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
