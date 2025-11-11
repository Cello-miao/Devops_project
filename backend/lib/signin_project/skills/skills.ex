defmodule SigninProject.Skills do
  @moduledoc "Skills context"

  import Ecto.Query, warn: false

  alias SigninProject.Accounts.User
  alias SigninProject.Repo
  alias SigninProject.Skills.Skill
  alias SigninProject.Tasks.Task

  def list_skills, do: Repo.all(Skill)

  def get_skill!(id), do: Repo.get!(Skill, id)

  def create_skill(attrs) do
    %Skill{}
    |> Skill.changeset(attrs)
    |> Repo.insert()
  end

  def update_skill(%Skill{} = skill, attrs) do
    skill
    |> Skill.changeset(attrs)
    |> Repo.update()
  end

  def delete_skill(%Skill{} = skill), do: Repo.delete(skill)

  # User <-> Skill many_to_many
  def add_skill_to_user(user_id, skill_id) do
    user = Repo.get!(User, user_id)
    skill = Repo.get!(Skill, skill_id)

    Repo.insert_all("users_skills", [%{user_id: user.id, skill_id: skill.id}],
      on_conflict: :nothing
    )

    {:ok, user}
  end

  def remove_skill_from_user(user_id, skill_id) do
    from(us in "users_skills", where: us.user_id == ^user_id and us.skill_id == ^skill_id)
    |> Repo.delete_all()

    {:ok, :deleted}
  end

  # Task -> Skill many_to_one assignment
  def assign_skill_to_task(task_id, skill_id) do
    task = Repo.get!(Task, task_id)
    skill = Repo.get!(Skill, skill_id)

    task
    |> Task.changeset(%{skill_id: skill.id})
    |> Repo.update()
  end
end
