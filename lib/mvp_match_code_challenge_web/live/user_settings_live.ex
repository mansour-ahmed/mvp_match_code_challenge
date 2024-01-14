defmodule MvpMatchCodeChallengeWeb.UserSettingsLive do
  alias MvpMatchCodeChallenge.VendingMachine
  alias MvpMatchCodeChallenge.ApiTokens
  use MvpMatchCodeChallengeWeb, :live_view

  alias MvpMatchCodeChallenge.Accounts

  def render(assigns) do
    ~H"""
    <.header class="pb-12 sm:pb-24 sm:text-center">
      Account Settings
      <:subtitle>Manage your account settings here</:subtitle>
    </.header>
    <div class="flex flex-col sm:flex-row gap-12 sm:gap-0 sm:justify-between">
      <div class="w-full">
        <h2 class="text-xl sm:text-2xl font-semibold">Your active sessions</h2>
        <.list>
          <:item title="Active Web Sessions">
            <strong>
              <%= @user_active_tokens_count.session_token_count %>
            </strong>
          </:item>
          <:item title="Active API Tokens">
            <strong>
              <%= @user_active_tokens_count.api_token_count %>
            </strong>
          </:item>
        </.list>
        <.link
          data-confirm="Are you sure? Afterwards all of your active api & web tokens won't work anymore."
          href={~p"/users/log_out/all"}
          method="delete"
        >
          <.button class="bg-red-600 hover:bg-red-500 mt-8">Log out of all active sessions</.button>
        </.link>
      </div>
      <div class="w-full">
        <h2 class="text-xl sm:text-2xl font-semibold">Update your password</h2>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/users/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            field={@password_form[:username]}
            type="hidden"
            id="hidden_user_username"
            value={@current_username}
          />
          <.input field={@password_form[:password]} type="password" label="New password" required />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Password</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    password_changeset = Accounts.change_user_password(user)
    user_active_tokens_count = ApiTokens.get_user_active_tokens_count(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:username_form_current_password, nil)
      |> assign(:current_username, user.username)
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:user_active_tokens_count, user_active_tokens_count)

    {:ok, socket}
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event(
        "deposit_coin",
        %{"user" => %{"deposit" => deposit}},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    case VendingMachine.add_coin_to_user_deposit(current_user, String.to_integer(deposit)) do
      {:ok, user} ->
        deposit_form =
          user
          |> Accounts.change_user_deposit(%{deposit: nil})
          |> to_form()

        {:noreply,
         socket
         |> assign(deposit_form: deposit_form)
         |> put_flash(:success, "Coin deposited successfully")
         |> assign(current_user: user)}

      {:error, changeset} ->
        {:noreply, assign(socket, deposit_form: to_form(changeset))}
    end
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
