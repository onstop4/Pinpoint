defmodule Pinpoint.Locations.Broadcasting do
  alias Phoenix.PubSub
  alias Pinpoint.Locations

  def start_sharing_location(current_user_id, location \\ nil) do
    self_pid = self()

    Cachex.transaction(Pinpoint.CurrentLocationCache, [current_user_id], fn worker ->
      case Locations.get_value_from_cache(worker, current_user_id) do
        {pid, _} when pid != self_pid ->
          send(pid, :sharing_from_alternate_location)

        nil ->
          PubSub.broadcast!(
            Pinpoint.PubSub,
            Locations.get_pubsub_topic(current_user_id),
            {:started_sharing, current_user_id, location}
          )
      end

      Cachex.put(worker, current_user_id, {self_pid, location})

      ProcessWatcher.monitor(
        PinpointWeb.LocationBroadcastingWatcher,
        self_pid,
        {__MODULE__, :stop_sharing_location, [current_user_id, self_pid]}
      )
    end)
  end

  def stop_sharing_location(current_user_id, self_pid \\ self()) do
    Cachex.transaction(Pinpoint.CurrentLocationCache, [current_user_id], fn worker ->
      if match?({^self_pid, _}, Locations.get_value_from_cache(worker, current_user_id)) do
        Cachex.del(worker, current_user_id)

        PubSub.broadcast!(
          Pinpoint.PubSub,
          Locations.get_pubsub_topic(current_user_id),
          {:stopped_sharing, current_user_id}
        )
      end
    end)

    ProcessWatcher.demonitor(PinpointWeb.LocationBroadcastingWatcher, self())
  end

  def share_new_location(current_user_id, new_location) do
    self_pid = self()

    Cachex.transaction(Pinpoint.CurrentLocationCache, [current_user_id], fn worker ->
      if match?({^self_pid, _}, Locations.get_value_from_cache(worker, current_user_id)) do
        Cachex.put(worker, current_user_id, {self_pid, new_location})

        PubSub.broadcast!(
          Pinpoint.PubSub,
          Locations.get_pubsub_topic(current_user_id),
          {:new_location, current_user_id, new_location}
        )
      end
    end)
  end

  def update_sharing_status(from_user_id, to_user_id, status) do
    PubSub.broadcast!(
      Pinpoint.PubSub,
      Locations.get_pubsub_topic(to_user_id),
      {:updated_sharing_status, from_user_id, status}
    )
  end
end
