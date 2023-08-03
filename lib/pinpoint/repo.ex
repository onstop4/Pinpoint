defmodule Pinpoint.Repo do
  use Ecto.Repo,
    otp_app: :pinpoint,
    adapter: Ecto.Adapters.Postgres
end
