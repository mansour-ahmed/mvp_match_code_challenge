defmodule MvpMatchCodeChallengeWeb.HomeLive do
  use MvpMatchCodeChallengeWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="md:mt-[calc(50%_-_16rem)]">
      <div class="flex sm:flex-row flex-col justify-center items-center sm:justify-between gap-7">
        <div class="flex flex-col sm:items-start items-center gap-10">
          <h1 class="text-5xl sm:text-7xl font-bold bg-clip-text text-transparent bg-gradient-to-tr from-orange-600 via-orange-400 to-orange-100 text-center sm:text-left">
            Phoenix Vending Machine
          </h1>
          <.link href={~p"/products"}>
            <button class="text-lg sm:text-xl font-semibold text-white bg-orange-600 rounded-lg p-3 sm:p-4 hover:bg-orange-500">
              Go to products
            </button>
          </.link>
        </div>
        <.blob_container>
          <img src="/images/landing_card.png" alt="App Logo" class="w-full" />
        </.blob_container>
      </div>
    </div>
    """
  end

  slot(:inner_block, required: true)

  def blob_container(assigns) do
    ~H"""
    <div class="flex w-full group">
      <img
        src={~s(images/blob-orange.svg)}
        class="mr-[-100%] w-full ease-out duration-300 group-hover:scale-105"
      />
      <div class="w-[calc(100%_-_1.5rem)] self-center rounded-lg overflow-hidden sm:w-[calc(100%_-_5rem)] z-10">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
