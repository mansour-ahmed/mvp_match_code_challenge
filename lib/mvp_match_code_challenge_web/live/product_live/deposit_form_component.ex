defmodule MvpMatchCodeChallengeWeb.ProductLive.DepositFormComponent do
  use MvpMatchCodeChallengeWeb, :live_component

  alias MvpMatchCodeChallenge.{Accounts, VendingMachine}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row items-center justify-between">
      <div>
        <.header>Your current deposit</.header>
        <strong class="text-5xl"><%= @user.deposit %></strong>
      </div>
      <.simple_form for={@form} id="deposit_form" phx-submit="deposit_coin" phx-target={@myself}>
        <.input
          field={@form[:deposit]}
          type="select"
          options={@valid_coins |> Enum.map(&{&1, &1})}
          label="Coin"
          class="text-center"
        />
        <:actions>
          <.button phx-disable-with="Depositing..." class="bg-green-600 hover:bg-green-500">
            Deposit coin
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{user: user} = assigns, socket) do
    valid_coins = VendingMachine.get_valid_coins()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(valid_coins: valid_coins)
     |> assign_form_for_user(user)}
  end

  @impl true
  def handle_event(
        "deposit_coin",
        %{"user" => %{"deposit" => deposit}},
        %{assigns: %{user: user}} = socket
      ) do
    try do
      deposit_coins(socket, user, String.to_integer(deposit))
    rescue
      _ ->
        {:noreply, socket}
    end
  end

  defp deposit_coins(socket, user, deposit) do
    case VendingMachine.add_coin_to_user_deposit(user, deposit) do
      {:ok, user} ->
        notify_parent({:saved, user})
        {:noreply, assign_form_for_user(socket, user)}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form_for_user(socket, user) do
    assign_form(
      socket,
      user
      |> Accounts.change_user_deposit()
    )
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
