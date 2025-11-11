defmodule SigninProject.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :surname, :string, null: false
      add :email, :string, null: false
      add :role, :string, null: false, default: "user"
      add :password_hash, :string, null: false

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
