defmodule ProcomWeb.Router do
  use ProcomWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ProcomWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]

    plug OpenApiSpex.Plug.PutApiSpec, module: ProcomWeb.ApiSpec
  end

  scope "/", ProcomWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/" do
    pipe_through :browser

    get "/swaggerui", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi"
  end

  scope "/api" do
    # TODO: define auth for this scope
    pipe_through :api

    # this must be in another scope to avoid problems with nested
    # module names
    get "/openapi", OpenApiSpex.Plug.RenderSpec, []
  end

  # Other scopes may use custom stacks.
  scope "/api", ProcomWeb do
    # TODO: define auth for this scope
    pipe_through :api

    get "/compare", ProductController, :compare
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:procom, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ProcomWeb.Telemetry
    end
  end
end
