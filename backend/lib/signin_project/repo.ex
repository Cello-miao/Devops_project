defmodule SigninProject.Repo do
  use Ecto.Repo,
    otp_app: :signin_project,
    adapter: Ecto.Adapters.Postgres
end
