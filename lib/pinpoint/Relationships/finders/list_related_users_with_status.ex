defmodule Pinpoint.Relationships.Finders.ListRelatedUsersWithStatus do
  import Ecto.Query, warn: false
  alias Pinpoint.Accounts.User
  alias Pinpoint.Repo
  alias Pinpoint.Relationships.Relationship

  def find(original_user_id, status, opts \\ []) do
    if Keyword.get(opts, :reverse, false) do
      from(relationship in Relationship,
        where: relationship.to_id == ^original_user_id.id and relationship.status == ^status,
        join: user_from in User,
        on: user_from.id == relationship.from_id,
        select: user_from
      )
    else
      from(relationship in Relationship,
        where: relationship.from_id == ^original_user_id and relationship.status == ^status,
        join: user_to in User,
        on: user_to.id == relationship.to_id,
        select: user_to
      )
    end
    |> Repo.all()
  end
end
