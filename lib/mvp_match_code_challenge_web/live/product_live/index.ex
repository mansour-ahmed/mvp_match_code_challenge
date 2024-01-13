defmodule MvpMatchCodeChallengeWeb.ProductLive.Index do
  use MvpMatchCodeChallengeWeb, :live_view

  alias MvpMatchCodeChallenge.Products
  alias MvpMatchCodeChallenge.Products.Product

  @impl true
  def render(assigns) do
    ~H"""
    <div :if={buyer?(@current_user)} class="pb-16">
      <.live_component
        id="deposit_form"
        module={MvpMatchCodeChallengeWeb.ProductLive.DepositFormComponent}
        user={@current_user}
      />
    </div>
    <.header>
      Listing Products
      <:actions>
        <%= if  seller?(@current_user) do %>
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
      <:col :let={{_id, product}} label="Product name"><%= product.product_name %></:col>
      <:col :let={{_id, product}} label="Amount available"><%= product.amount_available %></:col>
      <:col :let={{_id, product}} label="Cost"><%= product.cost %></:col>
      <:action :let={{_id, product}}>
        <%= if @current_user do %>
          <%= if product.seller_id == @current_user.id do %>
            <div class="sr-only">
              <.link navigate={~p"/products/#{product}"}>Show</.link>
            </div>
            <.link patch={~p"/products/#{product}/edit"}>Edit</.link>
          <% end %>
          <%= if product.amount_available > 0 && @current_user.role == :buyer do %>
            <.live_component
              module={MvpMatchCodeChallengeWeb.ProductLive.BuyFormComponent}
              id={"buy-product-#{product.id}"}
              product={product}
              user={@current_user}
            />
          <% end %>
        <% end %>
      </:action>
      <:action :let={{id, product}}>
        <%= if product_owner?(product,@current_user) do %>
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

  defp apply_action(socket, :edit, %{"id" => id}),
    do:
      socket
      |> assign(:page_title, "Edit Product")
      |> assign(:product, Products.get_product!(id))

  defp apply_action(socket, :new, _params),
    do:
      socket
      |> assign(:page_title, "New Product")
      |> assign(:product, %Product{})

  defp apply_action(socket, :index, _params),
    do:
      socket
      |> assign(:page_title, "Listing Products")
      |> assign(:product, nil)

  @impl true
  def handle_info({MvpMatchCodeChallengeWeb.ProductLive.FormComponent, {:saved, product}}, socket) do
    {:noreply, stream_insert(socket, :products, product, at: 0)}
  end

  @impl true
  def handle_info(
        {MvpMatchCodeChallengeWeb.ProductLive.DepositFormComponent, {:saved, user}},
        socket
      ) do
    {:noreply,
     socket
     |> assign(:current_user, user)
     |> put_flash(:info, "Coin deposited successfully")}
  end

  @impl true
  def handle_info(
        {MvpMatchCodeChallengeWeb.ProductLive.BuyFormComponent,
         {:transaction_complete, product_transaction}},
        socket
      ) do
    current_user = socket.assigns.current_user

    updated_user = %{
      current_user
      | deposit: current_user.deposit - product_transaction.total_cost_to_buyer
    }

    products = Products.list_products()

    {:noreply,
     socket
     |> assign(:current_user, updated_user)
     |> put_flash(:info, "Product bought successfully")
     |> stream(:products, products)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = Products.get_product!(id)
    {:ok, _} = Products.delete_product(product)

    {:noreply, stream_delete(socket, :products, product)}
  end

  defp buyer?(user), do: user && user.role == :buyer
  defp seller?(user), do: user && user.role == :seller
  defp product_owner?(product, user), do: user && product.seller_id == user.id
end
