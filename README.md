Graphex
=======

[![Build Status](https://travis-ci.org/stocks29/graphex.svg)](https://travis-ci.org/stocks29/graphex)

A library for composing and executing task graphs in elixir.

### Add as Dependency

```elixir
{:graphex, "~> 0.2.1"}
```

Also, be sure to add `:graphex` to your application's list of OTP applications since it has a supervision tree that must be started before using the library.

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

## Errors and Retries

Each node can be automatically retried if the function causes the process to die. In order to automatically retry, just set the `:tries` attribute to a number greater than 1.

```elixir
  [name: :b, fun: &something_that_might_error/0, deps: [:some_data], tries: 3],
```

This would automatically retry vertex `:b` up to 3 times.

If the node fails all tries, it will publish `{:error, {:graphex, some_error}}` to all of the nodes that depend on it. The dependent nodes can then either continue their processing or simply return an error which will be passed along to the nodes which depend on it.
