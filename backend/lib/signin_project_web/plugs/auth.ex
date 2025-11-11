defmodule SigninProjectWeb.Plugs.Auth do
  @moduledoc """
  Authentication plug for verifying JWT tokens and loading the current user.
  Checks both the JWT cookie and XSRF token header for security.
  """
  import Plug.Conn

  alias SigninProject.Accounts
  alias SigninProject.Auth.Token

  def fetch_current_user(conn, _opts) do
    token = conn |> fetch_cookies() |> Map.get(:cookies) |> Map.get("jwt")

    case Token.verify_jwt(token) do
      {:ok, claims} ->
        xsrf_claim = claims["xsrf"]
        req_xsrf = get_req_header(conn, "x-xsrf-token") |> List.first()

        if req_xsrf && req_xsrf == xsrf_claim do
          user = String.to_integer(claims["sub"]) |> Accounts.get_user_with_skills!()

          conn
          |> assign(:current_user, user)
          |> assign(:current_role, claims["role"])
        else
          conn
          |> assign(:current_user, nil)
          |> assign(:current_role, nil)
        end

      _ ->
        conn
        |> assign(:current_user, nil)
        |> assign(:current_role, nil)
    end
  end

  def require_authenticated(conn, _opts) do
    case conn.assigns[:current_user] do
      %SigninProject.Accounts.User{} ->
        conn

      _ ->
        conn
        |> send_resp(:unauthorized, Jason.encode!(%{error: "unauthorized"}))
        |> halt()
    end
  end

  # Plug behaviour
  def init(opts), do: opts

  def call(conn, opts) do
    fetch_current_user(conn, opts)
  end
end
