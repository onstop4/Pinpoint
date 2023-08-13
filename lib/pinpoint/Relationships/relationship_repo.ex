defmodule Pinpoint.Relationships.RelationshipRepo do
  alias Pinpoint.Repo
  alias Pinpoint.Relationships.Relationship

  def list_relationships() do
    Repo.all(Relationship)
  end

  def get_relationship!(id), do: Repo.get!(Relationship, id)

  def get_relationship!(user_from_id, user_to_id) do
    Repo.get_by!(Relationship, from_id: user_from_id, to_id: user_to_id)
  end

  def get_relationship(user_from_id, user_to_id) do
    Repo.get_by(Relationship, from_id: user_from_id, to_id: user_to_id)
  end

  def create_relationship(attrs \\ %{}) do
    %Relationship{}
    |> Relationship.changeset(attrs)
    |> Repo.insert()
  end

  def update_relationship(%Relationship{} = relationship, attrs) do
    relationship
    |> Relationship.changeset(attrs)
    |> Repo.update()
  end

  def delete_relationship(%Relationship{} = relationship) do
    Repo.delete(relationship)
  end

  def change_relationship(%Relationship{} = relationship, attrs \\ %{}) do
    Relationship.changeset(relationship, attrs)
  end
end
