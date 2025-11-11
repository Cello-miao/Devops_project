defmodule SigninProject.Skills.Skill do
  @moduledoc """
  Skill schema representing abilities that users can have and tasks can require.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "skills" do
    field :name, :string

    many_to_many :users, SigninProject.Accounts.User,
      join_through: "users_skills",
      on_replace: :delete

    timestamps()
  end

  def changeset(skill, attrs) do
    skill
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
