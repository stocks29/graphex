defmodule Graphex.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, Dict.put(opts, :name, __MODULE__))
  end

  def start_graph_supervisor do
    Supervisor.start_child(__MODULE__, [])
  end

  def init(:ok) do
    children = [
      supervisor(Graphex.GraphSupervisor, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
