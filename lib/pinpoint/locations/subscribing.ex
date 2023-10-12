defmodule Pinpoint.Locations.Subscribing do
  alias Phoenix.PubSub
  alias Pinpoint.Locations

  def subscribe(user_id) do
    PubSub.subscribe(Pinpoint.PubSub, Locations.get_pubsub_topic(user_id))
  end

  def subscribe_to_personal(user_id) do
    PubSub.subscribe(Pinpoint.PubSub, Locations.get_personal_pubsub_topic(user_id))
  end

  def unsubscribe(user_id) do
    PubSub.unsubscribe(Pinpoint.PubSub, Locations.get_pubsub_topic(user_id))
  end

  def unsubscribe_from_personal(user_id) do
    PubSub.unsubscribe(Pinpoint.PubSub, Locations.get_personal_pubsub_topic(user_id))
  end

  def unsubscribe_from_friends(friends) do
    Enum.each(friends, fn user ->
      PubSub.unsubscribe(Pinpoint.PubSub, Locations.get_pubsub_topic(user.id))
    end)
  end
end
