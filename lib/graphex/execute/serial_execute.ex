defmodule Graphex.Execute.SerialExecute do
  require Logger

  alias Graphex.Dag

  def exec_bf(dag) do
    exec_bf(dag, Dag.start_verticies(dag), %{})
  end

  defp exec_bf(_dag, [], results), do: results
  defp exec_bf(dag, [vert|verts], results) do
    Logger.debug "considering vertex #{inspect vert}"
    out_neighbors = Dag.downstreams(dag, vert)
    {results, new_verts} = process_vertex_if_deps_met(dag, vert, verts, results)
    exec_bf(dag, Enum.uniq(new_verts ++ out_neighbors), results)
  end

  defp process_vertex_if_deps_met(dag, vert, verts, results) do
    {^vert, label} = Dag.vertex(dag, vert)
    deps = label[:deps]
    fun = wrap_deps_only_fn(label[:fun], deps)
    if deps_satisfied?(deps, results) do
      Logger.debug "deps satisfied for #{inspect vert}"
      results = process_vertex_if_no_result(vert, fun, results, Map.has_key?(results, vert))
      {results, verts}
    else
      # Deps not yet met, so append this vert onto the end so we can try
      # it again later
      Logger.debug "deps not satisfied for #{inspect vert}"
      {results, verts ++ [vert]}
    end
  end

  defp process_vertex_if_no_result(_vert, _fun, results, true), do: results
  defp process_vertex_if_no_result(vert, fun, results, false) do
    Logger.debug "processing vertex #{inspect vert}"
    process_vertex_and_record(vert, fun, results)
  end

  defp process_vertex_and_record(vert, fun, results) do
    Map.put(results, vert, fun.(results))
  end

  def deps_satisfied?(deps, results) do
    deps_satisfied?(deps, results, true)
  end

  def deps_satisfied?(_deps, _results, false), do: false
  def deps_satisfied?([], _results, t_or_f), do: t_or_f
  def deps_satisfied?([h|t], results, true) do
    deps_satisfied?(t, results, Map.has_key?(results,h))
  end

  def wrap_deps_only_fn(fun, deps) do
    fn results ->
      results
      |> Map.take(deps)
      |> fun.()
    end
  end

end
