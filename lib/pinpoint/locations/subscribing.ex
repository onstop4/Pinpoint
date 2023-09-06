defmodule Pinpoint.Locations.Subscribing do
  alias Phoenix.PubSub
  alias Pinpoint.Locations

  def subscribe(user_id) do
    PubSub.subscribe(Pinpoint.PubSub, Locations.get_pubsub_topic(user_id))
  end

  def unsubscribe(user_id) do
    PubSub.unsubscribe(Pinpoint.PubSub, Locations.get_pubsub_topic(user_id))
  end

  def subscribe_to_friends(current_user_id, columns, transform) do
    for user <-
          Pinpoint.Relationships.Finders.ListFriendsSharingLocations.find(
            current_user_id,
            columns
          ),
        :ok = subscribe(user.id),
        result = Locations.get_value_from_cache(user.id),
        {_, location} = result,
        do: transform.(user, location)
  end

  def unsubscribe_from_friends(friends) do
    Enum.each(friends, fn user ->
      PubSub.unsubscribe(Pinpoint.PubSub, Locations.get_pubsub_topic(user.id))
    end)
  end
end
