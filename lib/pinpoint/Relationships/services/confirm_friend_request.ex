defmodule Pinpoint.Relationships.Services.ConfirmFriendRequest do
  alias Pinpoint.Repo
  alias Pinpoint.Relationships.{FriendshipInfoRepo, Relationship, RelationshipRepo}

  def call(
        %Relationship{from_id: from_user_id, to_id: to_user_id, status: :pending_friend} =
          existing_relationship
      ) do
    Repo.transaction(fn ->
      with {:ok, to_from_relationship} <-
             RelationshipRepo.create_relationship(%{
               from_id: to_user_id,
               to_id: from_user_id,
               status: :friend
             }),
           {:ok, from_to_relationship} <-
             RelationshipRepo.update_relationship(existing_relationship, %{status: :friend}),
           {:ok, _} <-
             FriendshipInfoRepo.create_friendship_info(%{relationship_id: from_to_relationship.id}),
           {:ok, _} <-
             FriendshipInfoRepo.create_friendship_info(%{relationship_id: to_from_relationship.id}) do
        {from_to_relationship, to_from_relationship}
      end
    end)
  end
end
