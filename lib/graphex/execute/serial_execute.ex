defmodule Graphex.Execute.SerialExecute do
  require Logger

  def exec_bf(dag) do
    exec_bf(dag, start_vs(dag), %{})
  end

  defp exec_bf(_dag, [], results), do: results
  defp exec_bf(dag, [vert|verts], results) do
    Logger.debug "considering vertex #{inspect vert}"
    more_out_verts = out_virts(dag, :digraph.out_edges(dag, vert))
    {results, new_verts} = process_vertex_if_deps_met(dag, vert, verts, results)
    exec_bf(dag, Enum.uniq(new_verts ++ more_out_verts), results)
  end

  defp process_vertex_if_deps_met(dag, vert, verts, results) do
    {^vert, label} = :digraph.vertex(dag, vert)
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

  def start_vs(dag) do
    for v <- :digraph.vertices(dag),
      in_edges = :digraph.in_edges(dag, v),
      length(in_edges) == 0 do
        v
    end
  end

  def out_virts(dag, edges) do
    for e <- edges do
      out_virt dag, e
    end
  end

  def out_virt(dag, e) do
    {^e, _, v, _} = :digraph.edge(dag, e)
    v
  end

  def wrap_deps_only_fn(fun, deps) do
    fn results ->
      results
      |> Map.take(deps)
      |> fun.()
    end
  end

end
