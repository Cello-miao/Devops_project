defmodule SigninProject.Auth.Token do
  @moduledoc "Helpers for JWT generation and verification using Joken"

  @algo "HS256"
  @expiry_seconds 30 * 24 * 60 * 60

  def generate_xsrf_token do
    # generate enough random bytes so base64 url encoding yields >=50 chars
    :crypto.strong_rand_bytes(38) |> Base.url_encode64(padding: false) |> binary_part(0, 50)
  end

  def claims_for_user(user, xsrf_token) do
    %{
      "xsrf" => xsrf_token,
      "sub" => to_string(user.id),
      "role" => user.role,
      "exp" => DateTime.utc_now() |> DateTime.add(@expiry_seconds, :second) |> DateTime.to_unix()
    }
  end

  defp secret, do: Application.fetch_env!(:signin_project, :jwt_secret)

  def generate_jwt(user) do
    xsrf = generate_xsrf_token()
    claims = claims_for_user(user, xsrf)

    jwk = JOSE.JWK.from_oct(secret())

    {_, jws} = JOSE.JWT.sign(jwk, %{"alg" => @algo}, claims) |> JOSE.JWS.compact()

    {:ok, jws, xsrf}
  end

  def verify_jwt(token) do
    jwk = JOSE.JWK.from_oct(secret())

    case JOSE.JWT.verify_strict(jwk, [@algo], token) do
      {true, jwt, _jws} ->
        {:ok, jwt.fields}

      _ ->
        {:error, :invalid_token}
    end
  end
end
