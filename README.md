# MvpMatchCodeChallenge

## Introduction

Your project description is clear and concise. Here are a few minor suggestions for improvement:

This project is a code challenge designed as part of an interview process.

It consists of a simple Elixir/Phoenix application that simulates a vending machine. The application allows users with a "seller" role to add, update, or remove products. Meanwhile, users with a "buyer" role can deposit coins into the machine and make purchases. The vending machine is programmed to accept only 5, 10, 20, 50, and 100 cent coins.

The app provides both an API and a user interface (UI) to manage these functionalities.

## Running the App

Clone the repository and navigate to the project directory:

```bash
git clone https://github.com/mansour-ahmed/mvp_match_code_challenge
cd mvp_match_code_challenge
```

### With Docker

If you don't have Elixir installed, you can run the app using Docker and Docker Compose. Ensure that Docker and Docker Compose are installed on your machine.

1. Build and start the Docker containers:

```bash
docker-compose up --build
```

The app will be accessible at http://localhost:4000.

### With Elixir

If you have Elixir installed, you can run the app directly on your machine.

1. Start the PostgreSQL service:

```bash
docker-compose up postgres -d
```

2. Install the dependencies:

```bash
mix deps.get
```

3. Create and migrate the database:

```bash
mix ecto.setup
```

4. Start the Phoenix server:

```bash
mix phx.server
```

The app will be accessible at http://localhost:4000.

## API Endpoints

### Users

- **POST `/api/users/`**: Create a new user.
  - Payload example

```

{
"username": "user_seller",
"password": "Hello world!",
"role": "seller",
"deposit": 100
}

```

- **GET `/api/users/:id`**: Get user details.
- **DELETE `/api/users/:id`**: Delete a user.

### Deposits

- **PUT `/api/users/:id/deposit/reset`**: Reset user's deposit (Buyers only).
- **POST `/api/users/:id/deposit/:coin`**: Add given coin to user's deposit (Buyers only).
- Payload example

```

{
"coin": 5
}

```

### Session

- **POST `/api/session/token`**: Generate an API token.
- Payload example

```

{
"username": "user_seller",
"password": "Hello world!"
}

```

- **DELETE `/api/session/log_out/all`**: Log out of all sessions.

### Products

- **GET `/api/products/`**: List all products.
- **GET `/api/products/:id`**: Get product details.
- **POST `/api/products/`**: Create a product (Sellers only).
- Payload example:

```

{
"cost": 5,
"amount_available": 10,
"product_name": "best product"
}

```

- **PUT `/api/products/:id`**: Update a product (Product's seller only).
- Payload example

```

{
"cost": 500
}

```

- **DELETE `/api/products/:id`**: Delete a product (Product's seller only).
- **POST `/api/products/:id/buy`**: Buy a product (Buyers only).
- Payload example

```

{
"transaction_product_amount": 2
}

```

## Test User Credentials

For testing purposes, the following user accounts have been created in the development environment:

1. **Buyer User**

- Username: `user_buyer`
- Password: `Hello world!`
- Role: Buyer
- Deposit: 1000

2. **Seller User**

- Username: `user_seller`
- Password: `Hello world!`
- Role: Seller

You can use these credentials to log in and test various functionalities of the application.

## License

MIT
