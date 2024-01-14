defmodule MvpMatchCodeChallengeWeb.Layouts do
  use MvpMatchCodeChallengeWeb, :html

  def app(assigns) do
    ~H"""
    <header class="py-2 px-2 sm:px-10 flex flex-col sm:flex-row justify-center items-center sm:justify-between">
      <.link href={~p"/"}>
        <img src="/images/logo.png" alt="App Logo" class="w-12 sm:w-24" />
      </.link>
      <ul class="relative flex flex-wrap items-center gap-4 sm:gap-8 px-4 sm:px-6 lg:px-8 sm:justify-end">
        <li :if={@current_user} class="sm:text-2xl leading-6 text-zinc-900">
          <%= @current_user.username %> (<%= @current_user.role %>)
        </li>
        <li>
          <.header_link href={~p"/products"}>
            Products
          </.header_link>
        </li>
        <%= if @current_user do %>
          <li>
            <.header_link href={~p"/users/settings"}>
              Settings
            </.header_link>
          </li>
          <li>
            <.header_link href={~p"/users/log_out"} method="delete">
              Log out
            </.header_link>
          </li>
        <% else %>
          <li>
            <.header_link href={~p"/users/register"}>
              Register
            </.header_link>
          </li>
          <li>
            <.header_link href={~p"/users/log_in"}>
              Log in
            </.header_link>
          </li>
        <% end %>
      </ul>
    </header>
    <main class="min-h-[calc(100vh_-_20rem)]">
      <div class="mx-auto max-w-4xl px-4">
        <.flash_group flash={@flash} />
        <div class="pt-16">
          <%= @inner_content %>
        </div>
      </div>
    </main>
    <.footer />
    """
  end

  attr :method, :string, default: "get", values: ["get", "post", "put", "patch", "delete"]
  attr :href, :string, required: true
  slot :inner_block

  defp header_link(assigns) do
    ~H"""
    <.link
      href={@href}
      method={@method}
      class="sm:text-2xl leading-6 text-orange-600 hover:text-orange-900"
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp footer(assigns) do
    ~H"""
    <footer class="flex flex-row items-center justify-center gap-8 px-2  pt-12 sm:pt-24 pb-6">
      <aside>
        Created by Ahmed Mansour
      </aside>
      <img src="/images/signature.jpg" class="w-28" alt="Ahmed's signature Logo" />
    </footer>
    """
  end

  embed_templates "layouts/*"
end
