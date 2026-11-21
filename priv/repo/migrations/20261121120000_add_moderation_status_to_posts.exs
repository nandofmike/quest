defmodule Claper.Repo.Migrations.AddModerationStatusToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :moderation_status, :string, default: "new", null: false
      add :moderated_at, :naive_datetime_usec
    end
  end
end
