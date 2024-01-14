defmodule MvpMatchCodeChallenge.Products.ProductTransaction do
  alias Ecto.Changeset
  use Ecto.Schema

  import Ecto.Changeset

  @valid_schema_fields ~w(transaction_product_amount product_total_cost product_available_amount buyer_available_funds)a

  embedded_schema do
    field :transaction_product_amount, :integer
    field :product_total_cost, :decimal
    field :product_available_amount, :integer
    field :buyer_available_funds, :decimal
  end

  def changeset(transaction_params) do
    %__MODULE__{}
    |> cast(transaction_params, @valid_schema_fields)
    |> validate_required(@valid_schema_fields)
    |> validate_number(:transaction_product_amount, greater_than: 0)
    |> validate_stock()
    |> validate_cost()
  end

  defp validate_stock(%Changeset{valid?: true} = changeset) do
    transaction_product_amount =
      changeset
      |> get_field(:transaction_product_amount)

    product_available_amount = get_field(changeset, :product_available_amount)

    if product_available_amount < transaction_product_amount do
      add_error(
        changeset,
        :transaction_product_amount,
        "must have enough stock to cover given product amount"
      )
    else
      changeset
    end
  end

  defp validate_stock(changeset), do: changeset

  defp validate_cost(%Changeset{valid?: true} = changeset) do
    buyer_available_funds = get_field(changeset, :buyer_available_funds)
    product_total_cost = get_field(changeset, :product_total_cost)

    if Decimal.gt?(product_total_cost, buyer_available_funds) do
      add_error(
        changeset,
        :transaction_product_amount,
        "must have enough funds to buy product with given amount"
      )
    else
      changeset
    end
  end

  defp validate_cost(changeset), do: changeset
end
