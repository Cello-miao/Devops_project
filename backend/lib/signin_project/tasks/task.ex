defmodule SigninProject.Tasks.Task do
  @moduledoc """
  Task schema representing tasks that can be assigned and associated with skills.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :title, :string
    field :description, :string

    belongs_to :skill, SigninProject.Skills.Skill

    timestamps()
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :description, :skill_id])
    |> validate_required([:title])
  end
end
