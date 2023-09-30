defmodule SynEventHandler do
  alias Phoenix.PubSub
  alias Pinpoint.Locations
  @behaviour :syn_event_handler

  @impl true
  def on_process_unregistered(Pinpoint.OnlineUsers, user_id, _pid, _meta, _reason),
    do:
      PubSub.local_broadcast(
        Pinpoint.PubSub,
        Locations.get_pubsub_topic(user_id),
        {:stopped_sharing, user_id}
      )
end
