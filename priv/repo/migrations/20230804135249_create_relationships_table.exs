defmodule Pinpoint.Repo.Migrations.CreateRelationshipsTable do
  use Ecto.Migration

  def change do
    create table(:relationships) do
      add :from_id, references(:users, on_delete: :delete_all, null: false)
      add :to_id, references(:users, on_delete: :delete_all, null: false)
      add :status, :string

      timestamps()
    end

    create index(:relationships, [:from_id])
    create index(:relationships, [:to_id])

    create unique_index(:relationships, [:from_id, :to_id],
             name: :relationships_from_id_to_id_index
           )

    create unique_index(:relationships, [:to_id, :from_id],
             name: :relationships_to_id_from_id_index
           )
  end
end
