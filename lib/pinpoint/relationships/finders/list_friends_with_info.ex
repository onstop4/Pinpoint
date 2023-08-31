defmodule Pinpoint.Relationships.Finders.ListFriendsWithInfo do
  import Ecto.Query, warn: false
  alias Pinpoint.Accounts.User
  alias Pinpoint.Repo
  alias Pinpoint.Relationships.{FriendshipInfo, Relationship}

  def find(original_user_id) do
    from(relationship in Relationship,
      where: relationship.from_id == ^original_user_id and relationship.status == :friend,
      join: user_to in User,
      on: user_to.id == relationship.to_id,
      join: friendship_info in FriendshipInfo,
      on: relationship.id == friendship_info.relationship_id,
      select: %{user: user_to, friendship_info: friendship_info}
    )
    |> Repo.all()
  end
end
