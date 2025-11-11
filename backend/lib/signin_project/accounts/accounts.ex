defmodule SigninProject.Accounts do
  @moduledoc "Accounts context for users"

  import Ecto.Query, warn: false

  alias SigninProject.Accounts.User
  alias SigninProject.Repo

  def get_user!(id), do: Repo.get!(User, id)

  @doc "Get a user by id and preload their skills (raises if not found)"
  def get_user_with_skills!(id) do
    User
    |> Repo.get!(id)
    |> Repo.preload(:skills)
  end

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def create_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc "Update an existing user. Returns {:ok, user} or {:error, changeset}."
  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  def authenticate_user(email, password) do
    require Logger

    case get_user_by_email(email) do
      nil ->
        Logger.debug("authenticate_user: no user found for email=#{email}")
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      user ->
        verify = Bcrypt.verify_pass(password, user.password_hash)

        Logger.debug(
          "authenticate_user: user_found=true id=#{user.id} verify_pass=#{inspect(verify)}"
        )

        if verify do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end
end
