defmodule Pinpoint.Locations do
  def get_pubsub_topic(user_id), do: "user_updates:#{user_id}"

  def get_value_from_cache(worker \\ Pinpoint.CurrentLocationCache, user_id) do
    {:ok, value} = Cachex.get(worker, user_id)
    value
  end
end
