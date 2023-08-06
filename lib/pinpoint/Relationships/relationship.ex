defmodule Pinpoint.Relationships.Relationship do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pinpoint.Relationships.FriendshipInfo

  schema "relationships" do
    field :from_id, :id
    field :to_id, :id
    field :status, Ecto.Enum, values: [:friend, :pending_friend, :blocked]

    has_one :friendship_info, FriendshipInfo

    timestamps()
  end

  @doc false
  def changeset(relationship, attrs) do
    relationship
    |> cast(attrs, [:from_id, :to_id, :status])
    |> validate_required([:from_id, :to_id, :status])
    |> Ecto.Changeset.unique_constraint([:from_id, :to_id],
      name: :relationships_from_id_to_id_index
    )
    |> Ecto.Changeset.unique_constraint([:to_id, :from_id],
      name: :relationships_to_id_from_id_index
    )
  end
end
