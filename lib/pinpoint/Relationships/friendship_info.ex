defmodule Pinpoint.Relationships.FriendshipInfo do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pinpoint.Relationships.Relationship

  @primary_key false

  schema "friendship_infos" do
    belongs_to :relationship, Relationship, foreign_key: :relationship_id, primary_key: true
    field :share_location, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(friendship_info, attrs) do
    friendship_info
    |> cast(attrs, [:relationship_id, :share_location])
    |> validate_required([:share_location])
    |> foreign_key_constraint(:relationship_id)
  end
end
