defmodule SigninProject.Repo.Migrations.CreateSkillsAndTasks do
  use Ecto.Migration

  def change do
    create table(:skills) do
      add :name, :string, null: false

      timestamps()
    end

    create unique_index(:skills, [:name])

    create table(:users_skills, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :skill_id, references(:skills, on_delete: :delete_all), null: false
    end

    create unique_index(:users_skills, [:user_id, :skill_id])

    # create a minimal tasks table if not present
    create table(:tasks) do
      add :title, :string, null: false
      add :description, :text
      add :skill_id, references(:skills, on_delete: :nilify_all)

      timestamps()
    end
  end
end
