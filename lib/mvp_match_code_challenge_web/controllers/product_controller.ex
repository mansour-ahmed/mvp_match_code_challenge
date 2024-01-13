defmodule MvpMatchCodeChallengeWeb.ProductController do
  use MvpMatchCodeChallengeWeb, :controller

  alias MvpMatchCodeChallenge.Products
  alias MvpMatchCodeChallenge.Products.Product

  action_fallback MvpMatchCodeChallengeWeb.FallbackController

  def index(conn, _params) do
    products = Products.list_products()
    render(conn, :index, products: products)
  end

  def show(conn, %{"id" => id}) do
    try do
      product = Products.get_product!(id)
      render(conn, :show, product: product)
    rescue
      Ecto.NoResultsError -> {:error, :not_found}
      Ecto.Query.CastError -> {:error, :bad_request}
      _ -> {:error, :internal_server_error}
    end
  end

  def create(
        %{
          assigns: %{
            current_user:
              %{
                role: :seller
              } = current_user
          }
        } = conn,
        product_params
      ) do
    seller_id = current_user.id

    valid_params =
      product_params
      |> Map.take(["product_name", "cost", "amount_available"])
      |> Map.put("seller_id", seller_id)

    with {:ok, %Product{} = product} <-
           Products.create_product(valid_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/products/#{product}")
      |> render(:show, product: product)
    end
  end

  def create(_conn, _params), do: {:error, :bad_request}

  def update(conn, %{"id" => id} = product_params) do
    try do
      with product <- Products.get_product!(id),
           {:ok, %Product{} = updated_product} <- Products.update_product(product, product_params) do
        render(conn, :show, product: updated_product)
      else
        {:error, %Ecto.Changeset{} = changeset} ->
          {:error, changeset}
      end
    rescue
      Ecto.NoResultsError ->
        {:error, :not_found}

      Ecto.Query.CastError ->
        {:error, :bad_request}

      _ ->
        {:error, :internal_server_error}
    end
  end

  def update(_conn, _params), do: {:error, :bad_request}

  def delete(conn, %{"id" => id}) do
    with product <- Products.get_product!(id),
         {:ok, %Product{}} <- Products.delete_product(product) do
      send_resp(conn, :no_content, "")
    else
      Ecto.NoResultsError -> {:error, :not_found}
      Ecto.Query.CastError -> {:error, :bad_request}
      _ -> {:error, :internal_server_error}
    end
  end
end
