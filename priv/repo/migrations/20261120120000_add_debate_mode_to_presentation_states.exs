defmodule Claper.Repo.Migrations.AddDebateModeToPresentationStates do
  use Ecto.Migration

  def change do
    alter table(:presentation_states) do
      add :debate_mode, :boolean, default: false, null: false
    end
  end
end
