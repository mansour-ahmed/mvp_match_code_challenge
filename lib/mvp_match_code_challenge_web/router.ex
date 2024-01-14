defmodule MvpMatchCodeChallengeWeb.Router do
  use MvpMatchCodeChallengeWeb, :router

  import MvpMatchCodeChallengeWeb.{UserAuth, UserSessionAuth, ApiAuth, ProductAuth}

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

    scope "/" do
      pipe_through [:api_require_authenticated_user]

      scope "/users" do
        scope "/:id" do
          pipe_through [:api_require_user_admin]

          get "/", UserController, :show
          delete "/", UserController, :delete

          scope "/" do
            pipe_through [
              :api_require_buyer_user
            ]

            put "/deposit/reset", UserController, :reset_deposit
            post "/deposit/:coin", UserController, :deposit
          end
        end
      end

      scope "/session" do
        delete "/log_out/all", UserSessionController, :delete_all_tokens
      end

      scope "/products" do
        scope "/" do
          pipe_through [:api_require_seller_user]
          post "/", ProductController, :create
        end

        scope "/:id" do
          pipe_through [:api_require_product_seller]
          put "/", ProductController, :update
          delete "/", ProductController, :delete
        end

        scope "/:id" do
          pipe_through [:api_require_buyer_user]
          post "/buy", VendingMachineController, :buy
        end
      end
    end

    # Public routes
    post "/users", UserController, :create
    post "/session/token", UserSessionController, :create_api_token
    get "/products/", ProductController, :index
    get "/products/:id", ProductController, :show
  end

  scope "/", MvpMatchCodeChallengeWeb do
    pipe_through [:browser]

    scope "/users" do
      pipe_through [:redirect_if_user_is_authenticated]

      live_session :redirect_if_user_is_authenticated,
        on_mount: [{MvpMatchCodeChallengeWeb.UserAuth, :redirect_if_user_is_authenticated}] do
        live "/register", UserRegistrationLive, :new
        live "/log_in", UserLoginLive, :new
      end

      post "/log_in", UserSessionController, :create
    end

    scope "/" do
      pipe_through [:require_authenticated_user]

      delete "/users/log_out/all", UserSessionController, :delete_all

      scope "/" do
        pipe_through [:require_seller_user]

        live_session :authenticated_seller_user_required,
          on_mount: [
            {MvpMatchCodeChallengeWeb.UserAuth, :ensure_authenticated},
            {MvpMatchCodeChallengeWeb.UserAuth, :ensure_seller_user}
          ] do
          live "/products/new", ProductLive.Index, :new
        end
      end

      live_session :authenticated_user_required,
        on_mount: [{MvpMatchCodeChallengeWeb.UserAuth, :ensure_authenticated}] do
        live "/users/settings", UserSettingsLive, :edit
      end

      scope "/" do
        pipe_through [:require_product_seller]

        live_session :product_seller_required,
          on_mount: [
            {MvpMatchCodeChallengeWeb.UserAuth, :ensure_authenticated},
            {
              MvpMatchCodeChallengeWeb.ProductAuth,
              :ensure_product_seller
            }
          ] do
          live "/products/:id/edit", ProductLive.Index, :edit
          live "/products/:id/show/edit", ProductLive.Show, :edit
        end
      end
    end

    # Public routes
    delete "/users/log_out", UserSessionController, :delete

    live_session :public_session,
      on_mount: [{MvpMatchCodeChallengeWeb.UserAuth, :mount_current_user}] do
      live "/", ProductLive.Index, :index
      live "/products", ProductLive.Index, :index
      live "/products/:id", ProductLive.Show, :show
    end
  end
end
