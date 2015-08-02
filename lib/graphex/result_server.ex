defmodule Graphex.ResultServer do
  use GenServer

  ### Public API

  def start_link(vertices, result_pid, opts \\ []) do
    GenServer.start_link(__MODULE__, [vertices, result_pid], opts)
  end

  def stop(server) do
    GenServer.cast(server, :stop)
  end

  def take(_server, []) do
    %{}
  end
  def take(server, items) do
    GenServer.call(server, {:take, items})
  end


  ### Callbacks

  def init([vertices, result_pid]) do
    {:ok, {vertices, result_pid, %{}}}
  end

  def handle_call({:take, items}, _from, state = {_, _, results}) do
    {:reply, Map.take(results, items), state}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def handle_info({:result, dep, result}, {vertices, result_pid, results}) do
    state = {List.delete(vertices, dep), result_pid, Map.put(results, dep, result)}
    send_results_if_all_received(state)
    {:noreply, state}
  end


  ### Private functions

  defp send_results_if_all_received({[], result_pid, results}) do
    send result_pid, {:results, results}
  end
  defp send_results_if_all_received(_state) do
    :ok
  end

end
