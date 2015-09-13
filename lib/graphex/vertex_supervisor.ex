defmodule Graphex.VertexSupervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def start_vertex(supervisor, vertex, deps, fun, downstream_procs, result_server, tries) do
    Supervisor.start_child(supervisor, [vertex, deps, fun, downstream_procs, result_server, tries])
  end

  def init(:ok) do
    children = [
      worker(Graphex.VertexServer, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
