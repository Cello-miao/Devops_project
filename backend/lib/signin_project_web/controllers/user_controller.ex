defmodule SigninProjectWeb.UserController do
  use SigninProjectWeb, :controller

  alias SigninProject.Accounts
  alias SigninProject.Auth.Token

  action_fallback SigninProjectWeb.FallbackController

  # Accept both flat params and nested %{"user" => params} and let the changeset
  # handle required field validation so we return 422 instead of a 400 mismatch.
  def sign_up(conn, params) when is_map(params) do
    params = Map.get(params, "user", params)

    case Accounts.create_user(params) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> json(%{id: user.id, role: user.role})

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

  # Allow nested payloads: {"user": {"email": ..., "password": ...}}
  def sign_in(conn, %{"user" => user_params}) when is_map(user_params) do
    sign_in(conn, user_params)
  end

  def sign_in(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        {:ok, jwt, xsrf} = Token.generate_jwt(user)

        conn
        |> put_resp_cookie("jwt", jwt, http_only: true, max_age: 30 * 24 * 60 * 60)
        |> put_status(:ok)
        |> json(%{xsrf_token: xsrf, role: user.role, id: user.id})

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "invalid_credentials"})
    end
  end

  def sign_out(conn, _params) do
    conn
    |> delete_resp_cookie("jwt")
    |> send_resp(:no_content, "")
  end

  # GET /api/users/me - return the currently authenticated user
  def me(conn, _params) do
    case conn.assigns[:current_user] do
      %SigninProject.Accounts.User{} = user ->
        conn
        |> put_status(:ok)
        |> json(user)

      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "unauthorized"})
    end
  end

  # PUT /api/users/me - update the currently authenticated user
  def update(conn, params) when is_map(params) do
    case conn.assigns[:current_user] do
      %SigninProject.Accounts.User{} = user ->
        params = Map.get(params, "user", params)

        case Accounts.update_user(user, params) do
          {:ok, user} ->
            conn
            |> put_status(:ok)
            |> json(user)

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

      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "unauthorized"})
    end
  end
end
