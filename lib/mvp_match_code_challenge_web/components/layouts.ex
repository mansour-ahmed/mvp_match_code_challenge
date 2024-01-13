defmodule MvpMatchCodeChallengeWeb.Layouts do
  use MvpMatchCodeChallengeWeb, :html

  def app(assigns) do
    ~H"""
    <header class="py-10 sm:py-8 px-2">
      <ul class="relative flex items-center gap-4 px-4 sm:px-6 lg:px-8 justify-end">
        <%= if @current_user do %>
          <li class="text-2xl leading-6 text-zinc-900">
            <%= @current_user.username %> (<%= @current_user.role %>)
          </li>
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
    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl">
        <.flash_group flash={@flash} />
        <%= @inner_content %>
      </div>
    </main>
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
      class="text-lg leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  embed_templates "layouts/*"
end
