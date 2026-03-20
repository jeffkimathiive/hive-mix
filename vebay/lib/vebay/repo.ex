defmodule Vebay.Repo do
  use Ecto.Repo,
    otp_app: :vebay,
    adapter: Ecto.Adapters.Postgres
end
