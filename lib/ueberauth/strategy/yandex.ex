defmodule Ueberauth.Strategy.Yandex do
  @moduledoc """
  Yandex Strategy for Überauth.
  """

  use Ueberauth.Strategy, uid_field: :id, default_scope: "login:email"

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles initial request for Yandex authentication.
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)

    params =
      [scope: scopes]
      |> with_optional(:login_hint, conn)
      |> with_optional(:display, conn)
      |> with_param(:login_hint, conn)
      |> with_param(:display, conn)
      |> with_param(:state, conn)

    opts = [redirect_uri: callback_url(conn)]

    redirect!(conn, Ueberauth.Strategy.Yandex.OAuth.authorize_url!(params, opts))
  end

  @doc """
  Handles the callback from Yandex.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    params = [code: code]
    opts = [redirect_uri: callback_url(conn)]
    case Ueberauth.Strategy.Yandex.OAuth.get_access_token(params, opts) do
      {:ok, token} ->
        fetch_user(conn, token)
      {:error, {error_code, error_description}} ->
        set_errors!(conn, [error(error_code, error_description)])
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:yandex_user, nil)
    |> put_private(:access_token, nil)
  end

  @doc """
  Fetches the uid field from the response.
  """
  def uid(conn) do
    uid_field =
      conn
      |> option(:uid_field)
      |> to_string

    conn.private.yandex_user[uid_field]
  end

  @doc """
  Includes the credentials from the yandex response.
  """
  def credentials(conn) do
    token        = conn.private.access_token
    scope_string = (token.other_params["scope"] || "")
    scopes       = String.split(scope_string, ",")

    %Credentials{
      expires: !!token.expires_at,
      expires_at: token.expires_at,
      scopes: scopes,
      token_type: Map.get(token, :token_type),
      refresh_token: token.refresh_token,
      token: token.access_token
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.yandex_user

    %Info{
      email: user["default_email"],
      first_name: user["first_name"],
      image: avatar_url(user["default_avatar_id"] || 0),
      last_name: user["last_name"],
      name: user["real_name"]
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the yandex callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.access_token,
        user: conn.private.yandex_user
      }
    }
  end


  defp fetch_user(conn, token) do
    conn = put_private(conn, :access_token, token)
    path = "https://login.yandex.ru/info?format=json"
    resp = Ueberauth.Strategy.Yandex.OAuth.get(token, path)

    case resp do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      {:ok, %OAuth2.Response{status_code: status_code, body: user}} when status_code in 200..399 ->
        put_private(conn, :yandex_user, user)
      {:error, %OAuth2.Response{status_code: status_code}} ->
        set_errors!(conn, [error("OAuth2", status_code)])
      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp with_param(opts, key, conn) do
    if value = conn.params[to_string(key)], do: Keyword.put(opts, key, value), else: opts
  end

  defp with_optional(opts, key, conn) do
    if option(conn, key), do: Keyword.put(opts, key, option(conn, key)), else: opts
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end

  defp avatar_url(avatar_id) do
    "https://avatars.yandex.net/get-yapic/#{avatar_id}/islands-retina-50"
  end
end
