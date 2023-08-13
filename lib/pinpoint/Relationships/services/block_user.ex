defmodule Pinpoint.Relationships.Services.BlockUser do
  alias Pinpoint.Repo
  alias Pinpoint.Relationships.RelationshipRepo
  alias Pinpoint.Relationships.Services.DeleteNonBlockedRelationshipsBetweenTwoUsers

  def call(from_user_id, to_user_id) do
    Repo.transaction(fn ->
      DeleteNonBlockedRelationshipsBetweenTwoUsers.call(from_user_id, to_user_id)

      RelationshipRepo.create_relationship(%{
        from_id: from_user_id,
        to_id: to_user_id,
        status: :blocked
      })
    end)
  end
end
