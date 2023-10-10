defmodule Pinpoint.Locations.Broadcaster do
  alias Phoenix.PubSub
  alias Pinpoint.Locations

  use GenServer

  @milliseconds_before_next_attempt 100

  def start_link(user_id) do
    GenServer.start_link(__MODULE__, user_id)
  end

  def stop(server) do
    GenServer.stop(server, :normal)
  end

  def update_location(server, new_location) do
    GenServer.cast(server, {:update_location, new_location})
  end

  @impl true
  def init(user_id) do
    state = %{user_id: user_id}

    case :syn.register(Pinpoint.OnlineUsers, user_id, self(), %{}) do
      :ok ->
        {:ok, state}

      {:error, :taken} ->
        case Locations.get_info(user_id) do
          {pid, _location} -> Process.exit(pid, :allow_alternate_broadcaster)
          nil -> nil
        end

        Process.sleep(@milliseconds_before_next_attempt)
        init(user_id)
    end
  end

  @impl true
  def handle_cast({:update_location, new_location}, state = %{user_id: user_id}) do
    :syn.update_registry(Pinpoint.OnlineUsers, user_id, new_location)

    PubSub.broadcast!(
      Pinpoint.PubSub,
      Locations.get_pubsub_topic(user_id),
      {:updated_location, user_id, new_location}
    )

    {:noreply, state}
  end
end
