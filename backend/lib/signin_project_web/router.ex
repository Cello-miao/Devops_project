defmodule SigninProjectWeb.Router do
  use SigninProjectWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SigninProjectWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]

    plug CORSPlug,
      origin: ["http://localhost:5173"],
      headers: ["x-xsrf-token", "content-type"],
      expose: ["x-xsrf-token"],
      credentials: true

    plug SigninProjectWeb.Plugs.Auth, :fetch_current_user
  end

  scope "/", SigninProjectWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  scope "/api", SigninProjectWeb do
    pipe_through :api

    post "/users/sign_up", UserController, :sign_up
    post "/users/sign_in", UserController, :sign_in
    post "/users/sign_out", UserController, :sign_out
    get "/users/me", UserController, :me
    put "/users/me", UserController, :update

    # skills CRUD
    get "/skills", SkillController, :index
    post "/skills", SkillController, :create
    get "/skills/:id", SkillController, :show
    put "/skills/:id", SkillController, :update
    delete "/skills/:id", SkillController, :delete

    # user-skill management
    post "/users/:userid/skills/:skillid", SkillController, :add_skill_to_user
    post "/users/:userid/skills", SkillController, :add_or_create_skill_to_user
    delete "/users/:userid/skills/:skillid", SkillController, :remove_skill_from_user

    # task-skill assignment
    put "/tasks/:taskid/skills/:skillid", SkillController, :assign_skill_to_task

    # tasks CRUD
    get "/tasks", TaskController, :index
    post "/tasks", TaskController, :create
    get "/tasks/:id", TaskController, :show
    put "/tasks/:id", TaskController, :update
    delete "/tasks/:id", TaskController, :delete
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:signin_project, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SigninProjectWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
