defmodule MvpMatchCodeChallengeWeb.ProductLive.BuyFormComponent do
  use MvpMatchCodeChallengeWeb, :live_component
  alias MvpMatchCodeChallenge.VendingMachine

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-left">
      <.modal :if={@show_modal} id={@id} show on_cancel={JS.push("toggle_modal", target: @myself)}>
        <.header>
          Buying product <%= @product.product_name %>
          <:subtitle>
            <p>Product cost: <strong><%= @product.cost %></strong></p>
            <p>Product available amount: <strong><%= @product.amount_available %></strong></p>
            <p>Your current deposit: <strong><%= @user.deposit %></strong></p>
          </:subtitle>
        </.header>
        <div class="w-full">
          <.simple_form
            for={@form}
            id="product_form"
            phx-submit="buy_product"
            phx-change="validate"
            phx-target={@myself}
          >
            <.input field={@form[:transaction_product_amount]} type="number" label="Amount" min="1" />
            <:actions>
              <.button phx-disable-with="Buying...">Buy product</.button>
            </:actions>
          </.simple_form>
        </div>
      </.modal>
      <.button phx-click="toggle_modal" phx-target={@myself}>Buy</.button>
    </div>
    """
  end

  @impl true
  def update(%{user: user, product: product} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(show_modal: false)
     |> assign_form(init_changeset(user, product))}
  end

  @impl true
  def handle_event("toggle_modal", _, socket),
    do: {:noreply, assign(socket, show_modal: !socket.assigns.show_modal)}

  @impl true
  def handle_event("validate", %{"product_transaction" => params}, socket),
    do: {:noreply, validate_transaction(socket, params)}

  @impl true
  def handle_event(
        "buy_product",
        %{"product_transaction" => %{"transaction_product_amount" => transaction_product_amount}},
        socket
      ) do
    try do
      buy_product(socket, String.to_integer(transaction_product_amount))
    rescue
      _ ->
        {:noreply, socket}
    end
  end

  defp buy_product(%{assigns: %{user: user, product: product}} = socket, amount) do
    case VendingMachine.buy_product(product, user, amount) do
      {:ok, product_transaction} ->
        notify_parent({:transaction_complete, product_transaction})
        {:noreply, assign_form(socket, init_changeset(user, product))}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp validate_transaction(%{assigns: %{user: user, product: product}} = socket, %{
         "transaction_product_amount" => amount
       }) do
    assign_form(
      socket,
      user
      |> init_changeset(product, amount)
      |> Map.put(:action, :validate)
    )
  end

  defp init_changeset(user, product, transaction_product_amount \\ "1") do
    transaction_product_amount =
      if transaction_product_amount == "", do: "0", else: transaction_product_amount

    product_total_cost =
      transaction_product_amount
      |> Decimal.new()
      |> Decimal.mult(product.cost)

    %{
      buyer_available_funds: user.deposit,
      product_available_amount: product.amount_available,
      transaction_product_amount: transaction_product_amount,
      product_total_cost: product_total_cost
    }
    |> VendingMachine.transaction_changeset()
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
