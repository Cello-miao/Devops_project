defmodule SigninProjectWeb.SkillController do
  use SigninProjectWeb, :controller

  alias SigninProject.Skills

  def index(conn, _params) do
    skills = Skills.list_skills()
    skills_json = Enum.map(skills, fn s -> %{id: s.id, name: s.name} end)
    json(conn, skills_json)
  end

  # Accept both flat params (%{"name" => "..."}) and nested params
  # (%{"skill" => %{"name" => "..."}}) to be tolerant of different clients.
  def create(conn, %{"skill" => skill_params}) when is_map(skill_params) do
    case Skills.create_skill(skill_params) do
      {:ok, skill} ->
        conn |> put_status(:created) |> json(%{id: skill.id, name: skill.name})

      {:error, changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(
            changeset,
            &SigninProjectWeb.ErrorHelpers.translate_error/1
          )

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: errors})
    end
  end

  def create(conn, %{"name" => _} = params) do
    case Skills.create_skill(params) do
      {:ok, skill} ->
        conn |> put_status(:created) |> json(%{id: skill.id, name: skill.name})

      {:error, changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(
            changeset,
            &SigninProjectWeb.ErrorHelpers.translate_error/1
          )

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: errors})
    end
  end

  def show(conn, %{"id" => id}) do
    skill = Skills.get_skill!(id)
    json(conn, %{id: skill.id, name: skill.name})
  end

  def update(conn, %{"id" => id} = params) do
    skill = Skills.get_skill!(id)

    case Skills.update_skill(skill, params) do
      {:ok, skill} ->
        json(conn, %{id: skill.id, name: skill.name})

      {:error, changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(
            changeset,
            &SigninProjectWeb.ErrorHelpers.translate_error/1
          )

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: errors})
    end
  end

  def delete(conn, %{"id" => id}) do
    skill = Skills.get_skill!(id)
    {:ok, _} = Skills.delete_skill(skill)
    send_resp(conn, :no_content, "")
  end

  # user-skill endpoints
  def add_skill_to_user(conn, %{"userid" => userid, "skillid" => skillid}) do
    {:ok, _} = Skills.add_skill_to_user(String.to_integer(userid), String.to_integer(skillid))
    send_resp(conn, :no_content, "")
  end

  def remove_skill_from_user(conn, %{"userid" => userid, "skillid" => skillid}) do
    {:ok, _} =
      Skills.remove_skill_from_user(String.to_integer(userid), String.to_integer(skillid))

    send_resp(conn, :no_content, "")
  end

  # POST /users/:userid/skills
  # Accepts either {"skillid": <id>} to attach an existing skill, or
  # {"name": "skill name"} to create the skill and attach it.
  def add_or_create_skill_to_user(conn, %{"userid" => userid} = params) do
    user_id = String.to_integer(userid)
    # Accept multiple possible keys for skill id from different clients
    skill_id_raw = params["skillid"] || params["skill_id"] || params["skillId"]
    skill_name = params["name"] || params["skill_name"]

    cond do
      not is_nil(skill_id_raw) ->
        skill_id =
          if is_binary(skill_id_raw), do: String.to_integer(skill_id_raw), else: skill_id_raw

        {:ok, _} = Skills.add_skill_to_user(user_id, skill_id)
        send_resp(conn, :no_content, "")

      not is_nil(skill_name) ->
        case Skills.create_skill(%{"name" => skill_name}) do
          {:ok, skill} ->
            {:ok, _} = Skills.add_skill_to_user(user_id, skill.id)
            conn |> put_status(:created) |> json(%{id: skill.id, name: skill.name})

          {:error, changeset} ->
            errors =
              Ecto.Changeset.traverse_errors(
                changeset,
                &SigninProjectWeb.ErrorHelpers.translate_error/1
              )

            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: errors})
        end

      true ->
        conn |> put_status(:bad_request) |> json(%{error: "missing skill id or name"})
    end
  end

  # task-skill endpoint
  def assign_skill_to_task(conn, %{"taskid" => taskid, "skillid" => skillid}) do
    task_id = String.to_integer(taskid)
    skill_id = String.to_integer(skillid)

    case Skills.assign_skill_to_task(task_id, skill_id) do
      {:ok, _task} ->
        send_resp(conn, :no_content, "")

      {:error, changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(
            changeset,
            &SigninProjectWeb.ErrorHelpers.translate_error/1
          )

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: errors})
    end
  end
end
