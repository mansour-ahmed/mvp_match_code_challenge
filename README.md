# MvpMatchCodeChallenge

## API Endpoints

### Users

- **POST `/api/users/`**: Create a new user.
- **GET `/api/users/:id`**: Get user details.
- **DELETE `/api/users/:id`**: Delete a user.

### Deposits

- **PUT `/api/users/:id/deposit/reset`**: Reset user's deposit (Buyers only).
- **POST `/api/users/:id/deposit/:coin`**: Add coin to deposit (Buyers only).

### Session

- **POST `/api/session/token`**: Generate API token.
- **DELETE `/api/session/log_out/all`**: Logout all sessions.

### Products

- **GET `/api/products/`**: List all products.
- **GET `/api/products/:id`**: Get product details.
- **POST `/api/products/`**: Create a product (Sellers only).
- **PUT `/api/products/:id`**: Update a product (Product's seller only).
- **DELETE `/api/products/:id`**: Delete a product (Product's seller only).
- **POST `/api/products/:id/buy`**: Buy a product (Buyers only).

## Test User Credentials

For testing purposes, the following user accounts have been created in the development environment:

1. **Buyer User**

   - Username: `user_buyer`
   - Password: `Hello world!`
   - Role: Buyer
   - Deposit: 1000
****
2. **Seller User**
   - Username: `user_seller`
   - Password: `Hello world!`
   - Role: Seller

You can use these credentials to log in and test various functionalities of the application.
