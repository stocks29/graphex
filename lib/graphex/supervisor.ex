defmodule Graphex.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, Dict.put(opts, :name, __MODULE__))
  end

  def start_vertex_supervisor do
    Supervisor.start_child(__MODULE__, [])
  end

  def stop_vertex_supervisor(graph_supervisor) do
    Supervisor.terminate_child(__MODULE__, graph_supervisor)
  end

  def init(:ok) do
    children = [
      supervisor(Graphex.VertexSupervisor, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
