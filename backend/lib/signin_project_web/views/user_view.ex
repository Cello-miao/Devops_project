defmodule SigninProjectWeb.UserView do
  @moduledoc false

  def render("show.json", %{user: user}) do
    %{
      id: user.id,
      name: user.name,
      surname: user.surname,
      email: user.email,
      role: user.role
    }
  end
end
