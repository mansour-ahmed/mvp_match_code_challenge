defmodule MvpMatchCodeChallengeWeb.Router do
  use MvpMatchCodeChallengeWeb, :router

  import MvpMatchCodeChallengeWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MvpMatchCodeChallengeWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :fetch_current_user

    plug :put_secure_browser_headers, %{
      "content-security-policy" => "default-src 'self' data:",
      "x-xss-protection" => "1; mode=block"
    }
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_api_user
  end

  scope "/api", MvpMatchCodeChallengeWeb do
    pipe_through :api

    scope "/users" do
      post "/token", UserSessionController, :create_api_token
    end

    scope "/products" do
      get "/", ProductController, :index
      get "/:id", ProductController, :show

      scope "/" do
        pipe_through [:api_require_authenticated_user]
        post "/", ProductController, :create
      end

      scope "/:id" do
        pipe_through [:api_require_authenticated_user, :api_require_product_seller]
        put "/", ProductController, :update
        delete "/", ProductController, :delete
      end
    end
  end

  scope "/", MvpMatchCodeChallengeWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", MvpMatchCodeChallengeWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:mvp_match_code_challenge, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MvpMatchCodeChallengeWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", MvpMatchCodeChallengeWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{MvpMatchCodeChallengeWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", MvpMatchCodeChallengeWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{MvpMatchCodeChallengeWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit

      live "/products", ProductLive.Index, :index
      live "/products/new", ProductLive.Index, :new
      live "/products/:id", ProductLive.Show, :show
    end
  end

  scope "/", MvpMatchCodeChallengeWeb do
    pipe_through [:browser, :require_authenticated_user, :require_product_seller]

    live_session :product_seller_required,
      on_mount: [
        {MvpMatchCodeChallengeWeb.UserAuth, :ensure_authenticated},
        {
          MvpMatchCodeChallengeWeb.UserAuth,
          :ensure_product_seller
        }
      ] do
      live "/products/:id/edit", ProductLive.Index, :edit
      live "/products/:id/show/edit", ProductLive.Show, :edit
    end
  end

  scope "/", MvpMatchCodeChallengeWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
  end
end
