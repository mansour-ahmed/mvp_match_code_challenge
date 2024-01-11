defmodule MvpMatchCodeChallengeWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use MvpMatchCodeChallengeWeb, :controller

  # Handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_resp_content_type("application/json")
    |> put_view(json: MvpMatchCodeChallengeWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, :bad_request}) do
    conn
    |> put_status(:bad_request)
    |> put_view(
      html: MvpMatchCodeChallengeWeb.ErrorHTML,
      json: MvpMatchCodeChallengeWeb.ErrorJSON
    )
    |> render(:"400")
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(
      html: MvpMatchCodeChallengeWeb.ErrorHTML,
      json: MvpMatchCodeChallengeWeb.ErrorJSON
    )
    |> render(:"404")
  end

  def call(conn, {:error, :internal_server_error}) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(
      html: MvpMatchCodeChallengeWeb.ErrorHTML,
      json: MvpMatchCodeChallengeWeb.ErrorJSON
    )
    |> render(:"500")
  end
end
