defmodule Graphex.Fun do
  require Logger

  alias Graphex.Dag
  alias Graphex.Execute.SerialExecute, as: S
  alias Graphex.Execute.ParallelExecute, as: P

  def html() do
    user = fn _ -> "Mike" end
    greeting = fn _ -> "Hi" end
    content = fn r -> "<h1>#{r[:greeting]} #{r[:user]}</h1>" end
    wrapper = fn r -> "<html><head></head><body>#{r[:content]}</body></html>" end

    side = fn _ -> IO.puts "I RAN" end

    dag = Dag.new
    |> Dag.add_vertex(name: :side, deps: [], fun: side)
    |> Dag.add_vertex(name: :user, deps: [], fun: user)
    |> Dag.add_vertex(name: :greeting, deps: [], fun: greeting)
    |> Dag.add_vertex(name: :content, deps: [:user, :greeting], fun: content)
    |> Dag.add_vertex(name: :wrapper, deps: [:content], fun: wrapper)

    Logger.debug("sync start")
    r = S.exec_bf(dag)
    Logger.info(r[:wrapper])
    Logger.debug("sync end")

    Logger.debug("async start")
    r = P.exec_bf(dag)
    Logger.info(r[:wrapper])
    Logger.debug("async end")
  end

  def run() do
    fun = sleep_fun();

    dag = Dag.new
    |> Dag.add_vertex(name: :a, deps: [], fun: fun)
    |> Dag.add_vertex(name: :b, deps: [:a], fun: fun)
    |> Dag.add_vertex(name: :c, deps: [:a], fun: fun)
    |> Dag.add_vertex(name: :d, deps: [:a], fun: fun)
    |> Dag.add_vertex(name: :e, deps: [:b, :c, :d], fun: fun)
    |> Dag.add_vertex(name: :f, deps: [:e], fun: fun)

    Logger.debug("sync start")
    S.exec_bf(dag)
    Logger.debug("sync end")

    Logger.debug("async start")
    P.exec_bf(dag)
    Logger.debug("async end")
  end

  def sleep_fun do
    fn results ->
      :timer.sleep(1000)
      Map.keys(results)
    end
  end
end
