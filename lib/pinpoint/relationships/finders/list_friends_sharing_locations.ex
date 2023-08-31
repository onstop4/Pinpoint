defmodule Pinpoint.Relationships.Finders.ListFriendsSharingLocations do
  import Ecto.Query, warn: false
  alias Pinpoint.Accounts.User
  alias Pinpoint.Repo
  alias Pinpoint.Relationships.{FriendshipInfo, Relationship}

  def find(original_user_id, columns) do
    query =
      from(relationship in Relationship,
        where: relationship.to_id == ^original_user_id and relationship.status == :friend,
        join: user_from in User,
        on: user_from.id == relationship.from_id,
        join: friendship_info in FriendshipInfo,
        on: relationship.id == friendship_info.relationship_id,
        where: friendship_info.share_location == true,
        select: map(user_from, ^columns),
        order_by: user_from.name
      )

    Repo.all(query)
  end
end
