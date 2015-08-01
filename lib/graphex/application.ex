defmodule Graphex.Application do
  use Application

  def start(_type, _args) do
    Graphex.Supervisor.start_link
  end
end
