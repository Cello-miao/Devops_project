defmodule SigninProjectWeb.UserControllerTest do
  use SigninProjectWeb.ConnCase

  alias SigninProject.Accounts

  @create_attrs %{
    "name" => "Alice",
    "surname" => "Smith",
    "email" => "alice@example.com",
    "password" => "supersecret"
  }

  test "sign_up creates user and returns 201", %{conn: conn} do
    conn = post(conn, "/api/users/sign_up", @create_attrs)
    assert json_response(conn, 201)["id"]
    assert json_response(conn, 201)["role"]
  end

  test "sign_in authenticates and returns xsrf token and sets jwt cookie", %{conn: conn} do
    # create a user in DB first
    {:ok, user} = Accounts.create_user(@create_attrs)

    signin_params = %{"email" => user.email, "password" => @create_attrs["password"]}

    conn = post(conn, "/api/users/sign_in", signin_params)

    body = json_response(conn, 200)
    assert Map.has_key?(body, "xsrf_token")
    assert body["id"] == user.id
    assert body["role"] == user.role

    # check cookie was set
    assert conn.resp_cookies["jwt"]
  end
end
