defmodule Pinpoint.Relationships.Services.DeleteNonBlockedRelationshipsBetweenTwoUsers do
  import Ecto.Query
  alias Pinpoint.Locations
  alias Pinpoint.Repo
  alias Pinpoint.Relationships.Relationship

  def call(user1_id, user2_id) do
    Locations.update_sharing_status(user1_id, user2_id, false)

    from(
      relationship in Relationship,
      where:
        ((relationship.from_id == ^user1_id and relationship.to_id == ^user2_id) or
           (relationship.from_id == ^user2_id and relationship.to_id == ^user1_id)) and
          relationship.status != :blocked
    )
    |> Repo.delete_all()
  end
end
