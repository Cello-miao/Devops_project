defmodule SigninProject.Accounts.User do
  @moduledoc """
  User schema representing authenticated users in the system.
  Users can have roles (employee/manager) and can be associated with skills.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :email, :name, :surname, :role]}
  schema "users" do
    field :name, :string
    field :surname, :string
    field :email, :string
    field :role, :string, default: "employee"
    field :password, :string, virtual: true
    field :password_hash, :string

    many_to_many :skills, SigninProject.Skills.Skill,
      join_through: "users_skills",
      on_replace: :delete

    timestamps()
  end

  @doc "Changeset for registration: validates password and hashes it."
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :surname, :email, :password, :role])
    |> validate_required([:name, :surname, :email, :password])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 6)
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  @doc "Changeset for updating a user: password is optional"
  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :surname, :email, :password, :role])
    |> validate_required([:name, :surname, :email])
    |> validate_format(:email, ~r/@/)
    # validate_length only runs when password present in changes
    |> validate_length(:password, min: 6)
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: pw}} = changeset) do
    put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(pw))
  end

  defp put_password_hash(changeset), do: changeset
end
