defmodule ProcessWatcher do
  use GenServer

  ## Client API

  def monitor(server_name, pid, mfa) do
    GenServer.call(server_name, {:monitor, pid, mfa})
  end

  def demonitor(server_name, pid) do
    GenServer.call(server_name, {:demonitor, pid})
  end

  ## Server API

  def start_link(options) do
    GenServer.start_link(__MODULE__, [], name: Keyword.get(options, :name))
  end

  def init(_) do
    Process.flag(:trap_exit, true)
    {:ok, %{processes: Map.new()}}
  end

  def handle_call({:monitor, pid, mfa}, _from, state) do
    Process.link(pid)
    {:reply, :ok, put_process(state, pid, mfa)}
  end

  def handle_call({:demonitor, pid}, _from, state) do
    case Map.fetch(state.processes, pid) do
      :error ->
        {:reply, :ok, state}

      {:ok, _mfa} ->
        Process.unlink(pid)
        {:reply, :ok, drop_process(state, pid)}
    end
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    case Map.fetch(state.processes, pid) do
      :error ->
        {:noreply, state}

      {:ok, {mod, func, args}} ->
        Task.start_link(fn -> apply(mod, func, args) end)
        {:noreply, drop_process(state, pid)}
    end
  end

  defp drop_process(state, pid) do
    %{state | processes: Map.delete(state.processes, pid)}
  end

  defp put_process(state, pid, mfa) do
    %{state | processes: Map.put(state.processes, pid, mfa)}
  end
end
