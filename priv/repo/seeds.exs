alias MvpMatchCodeChallenge.Repo
alias MvpMatchCodeChallenge.Accounts.User
alias MvpMatchCodeChallenge.Products.Product
import Ecto.Query

# Insert Users
users = [
  %{username: "user_buyer", password: "Hello world!", role: :buyer, deposit: 1000},
  %{username: "user_seller", password: "Hello world!", role: :seller}
]

Enum.each(users, fn user_attrs ->
  %User{}
  |> User.registration_changeset(user_attrs)
  |> Repo.insert()
end)

sellers = Repo.all(from u in User, where: u.role == ^:seller)

products = [
  %{
    product_name: "Product 1",
    amount_available: 10,
    cost: "10",
    seller_id: Enum.at(sellers, 1).id
  },
  %{
    product_name: "Product 2",
    amount_available: 15,
    cost: "15",
    seller_id: Enum.at(sellers, 1).id
  },
  %{
    product_name: "Product 3",
    amount_available: 20,
    cost: "20",
    seller_id: Enum.at(sellers, 1).id
  }
]

Enum.each(products, fn product_attrs ->
  %Product{}
  |> Product.changeset(product_attrs)
  |> Repo.insert()
end)

total_products = Repo.all(Product) |> Enum.count()
total_users = Repo.all(User) |> Enum.count()

IO.inspect("Seeds inserted successfully!")
IO.inspect("Users: #{total_users}")
IO.inspect("Products: #{total_products}")
