defmodule SigninProjectWeb.PageController do
  use SigninProjectWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
