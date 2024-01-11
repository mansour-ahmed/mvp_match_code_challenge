defmodule MvpMatchCodeChallenge.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :amount_available, :integer, null: false
      add :cost, :decimal, null: false
      add :product_name, :string, null: false
      add :seller_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:products, [:seller_id])
    create unique_index(:products, [:product_name])

    create constraint(:products, :cost, check: "cost > 0 AND cost <= 100000000")

    create constraint(:products, :amount_available,
             check: "amount_available > 0 AND amount_available <= 1000000"
           )

    create constraint(:products, :product_name,
             check: "LENGTH(product_name) > 0 AND LENGTH(product_name) <= 1000"
           )
  end
end
