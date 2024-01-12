defmodule MvpMatchCodeChallenge.Products.Product do
  use Ecto.Schema
  alias MvpMatchCodeChallenge.Accounts
  import Ecto.Changeset

  @valid_schema_fields ~w(amount_available cost product_name seller_id)a
  @max_product_name_length 1000
  @max_amount 1_000_000
  @max_cost 100_000_000

  schema "products" do
    field :amount_available, :integer
    field :cost, :decimal
    field :product_name, :string
    belongs_to :seller, MvpMatchCodeChallenge.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(product, attrs) do
    product
    |> cast(attrs, @valid_schema_fields)
    |> validate_seller_id(attrs)
    |> validate_amount_available()
    |> validate_cost()
    |> validate_product_name()
  end

  def amount_available_changeset(product, attrs) do
    product
    |> cast(attrs, [:amount_available])
    |> validate_amount_available()
  end

  defp validate_seller_id(changeset, attrs) do
    changeset
    |> validate_required([:seller_id])
    |> validate_existing_user(attrs[:seller_id])
  end

  defp validate_existing_user(changeset, nil), do: changeset

  defp validate_existing_user(changeset, user_id) do
    user = Accounts.get_user(user_id)

    cond do
      user == nil ->
        add_error(changeset, :seller_id, "does not exist")

      user.role != :seller ->
        add_error(changeset, :seller_id, "user must have a seller role")

      true ->
        changeset
    end
  end

  defp validate_amount_available(changeset) do
    changeset
    |> validate_required([:amount_available])
    |> validate_number(:amount_available,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: @max_amount
    )
  end

  defp validate_cost(changeset) do
    changeset
    |> validate_required([:cost])
    |> validate_number(:cost,
      greater_than: 0,
      less_than_or_equal_to: @max_cost
    )
  end

  defp validate_product_name(changeset) do
    changeset
    |> validate_required([:product_name])
    |> validate_length(:product_name, min: 1, max: @max_product_name_length)
    |> unique_constraint(:product_name)
  end
end
