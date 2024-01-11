defmodule MvpMatchCodeChallengeWeb.ProductLive.Index do
  use MvpMatchCodeChallengeWeb, :live_view

  alias MvpMatchCodeChallenge.Products
  alias MvpMatchCodeChallenge.Products.Product

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Products
      <:actions>
        <%= if @current_user.role == :seller do %>
          <.link patch={~p"/products/new"}>
            <.button>New Product</.button>
          </.link>
        <% end %>
      </:actions>
    </.header>

    <.table
      id="products"
      rows={@streams.products}
      row_click={fn {_id, product} -> JS.navigate(~p"/products/#{product}") end}
    >
      <:col :let={{_id, product}} label="Amount available"><%= product.amount_available %></:col>
      <:col :let={{_id, product}} label="Cost"><%= product.cost %></:col>
      <:col :let={{_id, product}} label="Product name"><%= product.product_name %></:col>
      <:action :let={{_id, product}}>
        <%= if product.seller_id == @current_user.id do %>
          <div class="sr-only">
            <.link navigate={~p"/products/#{product}"}>Show</.link>
          </div>
          <.link patch={~p"/products/#{product}/edit"}>Edit</.link>
        <% end %>
      </:action>
      <:action :let={{id, product}}>
        <%= if product.seller_id == @current_user.id do %>
          <.link
            phx-click={JS.push("delete", value: %{id: product.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        <% end %>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="product-modal"
      show
      on_cancel={JS.patch(~p"/products")}
    >
      <.live_component
        module={MvpMatchCodeChallengeWeb.ProductLive.FormComponent}
        id={@product.id || :new}
        title={@page_title}
        action={@live_action}
        product={@product}
        patch={~p"/products"}
        current_user={@current_user}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :products, Products.list_products())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Product")
    |> assign(:product, Products.get_product!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Product")
    |> assign(:product, %Product{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Products")
    |> assign(:product, nil)
  end

  @impl true
  def handle_info({MvpMatchCodeChallengeWeb.ProductLive.FormComponent, {:saved, product}}, socket) do
    {:noreply, stream_insert(socket, :products, product)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = Products.get_product!(id)
    {:ok, _} = Products.delete_product(product)

    {:noreply, stream_delete(socket, :products, product)}
  end
end
