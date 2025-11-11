defmodule SigninProjectWeb.TaskController do
  use SigninProjectWeb, :controller

  alias SigninProject.Tasks

  def index(conn, _params) do
    tasks = Tasks.list_tasks()

    tasks_json =
      Enum.map(tasks, fn t ->
        %{id: t.id, title: t.title, description: t.description, skill_id: t.skill_id}
      end)

    json(conn, tasks_json)
  end

  def create(conn, %{"task" => task_params}) when is_map(task_params) do
    case Tasks.create_task(task_params) do
      {:ok, task} ->
        conn
        |> put_status(:created)
        |> json(%{
          id: task.id,
          title: task.title,
          description: task.description,
          skill_id: task.skill_id
        })

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

  def create(conn, %{"title" => _} = params) do
    case Tasks.create_task(params) do
      {:ok, task} ->
        conn
        |> put_status(:created)
        |> json(%{
          id: task.id,
          title: task.title,
          description: task.description,
          skill_id: task.skill_id
        })

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
    task = Tasks.get_task!(id)

    json(conn, %{
      id: task.id,
      title: task.title,
      description: task.description,
      skill_id: task.skill_id
    })
  end

  def update(conn, %{"id" => id} = params) do
    task = Tasks.get_task!(id)

    case Tasks.update_task(task, params) do
      {:ok, task} ->
        json(conn, %{
          id: task.id,
          title: task.title,
          description: task.description,
          skill_id: task.skill_id
        })

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
    task = Tasks.get_task!(id)
    {:ok, _} = Tasks.delete_task(task)
    send_resp(conn, :no_content, "")
  end
end
