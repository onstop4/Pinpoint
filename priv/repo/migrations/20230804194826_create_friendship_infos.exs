defmodule Pinpoint.Repo.Migrations.CreateFriendshipInfos do
  use Ecto.Migration

  def change do
    create table(:friendship_infos, primary_key: false) do
      add :relationship_id, references(:relationships, on_delete: :delete_all),
        primary_key: true,
        null: false

      add :share_location, :boolean, default: false, null: false

      timestamps()
    end
  end
end
