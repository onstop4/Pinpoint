defmodule Pinpoint.Locations do
  alias Phoenix.PubSub

  def get_pubsub_topic(user_id), do: "user_updates:#{user_id}"

  def get_personal_pubsub_topic(user_id), do: "personal_" <> get_pubsub_topic(user_id)

  def get_info(user_id) do
    case :syn.lookup(Pinpoint.OnlineUsers, user_id) do
      :undefined -> nil
      found -> found
    end
  end

  def update_sharing_status(from_user_id, to_user_id, status) do
    PubSub.broadcast!(
      Pinpoint.PubSub,
      get_personal_pubsub_topic(to_user_id),
      {:updated_sharing_status, from_user_id, status}
    )
  end
end
