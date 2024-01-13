defmodule MvpMatchCodeChallengeWeb.ProductLive.Show do
  use MvpMatchCodeChallengeWeb, :live_view

  alias MvpMatchCodeChallenge.Products

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Product <%= @product.id %>
      <:subtitle>This is a product record from your database.</:subtitle>
      <:actions>
        <%= if @current_user && @product.seller_id == @current_user.id do %>
          <.link patch={~p"/products/#{@product}/show/edit"} phx-click={JS.push_focus()}>
            <.button>Edit product</.button>
          </.link>
        <% end %>
      </:actions>
    </.header>

    <.list>
      <:item title="Amount available"><%= @product.amount_available %></:item>
      <:item title="Cost"><%= @product.cost %></:item>
      <:item title="Product name"><%= @product.product_name %></:item>
    </.list>

    <.back navigate={~p"/products"}>Back to products</.back>

    <.modal
      :if={@live_action == :edit}
      id="product-modal"
      show
      on_cancel={JS.patch(~p"/products/#{@product}")}
    >
      <.live_component
        module={MvpMatchCodeChallengeWeb.ProductLive.FormComponent}
        id={@product.id}
        title={@page_title}
        action={@live_action}
        product={@product}
        patch={~p"/products/#{@product}"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:product, Products.get_product!(id))}
  end

  defp page_title(:show), do: "Show Product"
  defp page_title(:edit), do: "Edit Product"
end
