defmodule SigninProject.Repo.Migrations.CreateMissingSkillsTasks do
  use Ecto.Migration

  def change do
    # create skills table if it doesn't exist
    create_if_not_exists table(:skills) do
      add :name, :string, null: false

      timestamps()
    end

    create_if_not_exists unique_index(:skills, [:name])

    # create users_skills join table
    create_if_not_exists table(:users_skills, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :skill_id, references(:skills, on_delete: :delete_all), null: false
    end

    create_if_not_exists unique_index(:users_skills, [:user_id, :skill_id])

    # create tasks table if it doesn't exist
    create_if_not_exists table(:tasks) do
      add :title, :string, null: false
      add :description, :text
      add :skill_id, references(:skills, on_delete: :nilify_all)

      timestamps()
    end
  end
end
