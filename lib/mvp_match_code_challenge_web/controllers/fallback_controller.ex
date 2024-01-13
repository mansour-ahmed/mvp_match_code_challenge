defmodule MvpMatchCodeChallengeWeb.FallbackController do
  use MvpMatchCodeChallengeWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_resp_content_type("application/json")
    |> put_view(json: MvpMatchCodeChallengeWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, :bad_request, custom_message}) do
    conn
    |> put_status(:bad_request)
    |> put_resp_content_type("application/json")
    |> json(%{errors: %{details: custom_message}})
  end

  def call(conn, {:error, status})
      when status in [:bad_request, :unauthorized, :forbidden, :not_found, :internal_server_error] do
    errors_views = %{
      bad_request: :"400",
      unauthorized: :"401",
      forbidden: :"403",
      not_found: :"404",
      internal_server_error: :"500"
    }

    conn
    |> put_status(status)
    |> put_resp_content_type("application/json")
    |> put_view(MvpMatchCodeChallengeWeb.ErrorJSON)
    |> render(errors_views[status])
  end
end
