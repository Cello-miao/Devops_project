defmodule SigninProjectWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use SigninProjectWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: SigninProjectWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(html: SigninProjectWeb.ErrorHTML, json: SigninProjectWeb.ErrorJSON)
    |> render(:"404")
  end

  # This clause handles unauthorized errors
  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(json: SigninProjectWeb.ErrorJSON)
    |> render(:"401")
  end

  # This clause handles forbidden errors
  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> put_view(json: SigninProjectWeb.ErrorJSON)
    |> render(:"403")
  end
end
