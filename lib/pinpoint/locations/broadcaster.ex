defmodule Pinpoint.Locations.Broadcaster do
  alias Phoenix.PubSub
  alias Pinpoint.Locations

  use GenServer

  def start_link(user_id) do
    GenServer.start_link(__MODULE__, user_id)
  end

  def stop(server) do
    GenServer.stop(server, :normal)
  end

  def update_location(server, new_location) do
    GenServer.call(server, {:update_location, new_location})
  end

  @impl true
  def init(user_id) do
    state = %{user_id: user_id}

    case :syn.register(Pinpoint.OnlineUsers, user_id, self(), %{}) do
      :ok ->
        {:ok, state}

      {:error, :taken} ->
        {existing_pid, _location} = :syn.lookup(Pinpoint.OnlineUsers, user_id)
        Process.exit(existing_pid, :allow_alternate_broadcaster)
        Process.sleep(1)

        case :syn.register(Pinpoint.OnlineUsers, user_id, self(), %{}) do
          :ok -> {:ok, state}
          {:error, :taken} -> {:error, :existing_broadcaster}
        end
    end
  end

  @impl true
  def handle_call({:update_location, new_location}, _from, state = %{user_id: user_id}) do
    :syn.update_registry(Pinpoint.OnlineUsers, user_id, new_location)

    PubSub.broadcast!(
      Pinpoint.PubSub,
      Locations.get_pubsub_topic(user_id),
      {:updated_location, user_id, new_location}
    )

    {:reply, :ok, state}
  end
end
