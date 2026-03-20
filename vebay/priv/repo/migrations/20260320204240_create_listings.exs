defmodule Vebay.Repo.Migrations.CreateListings do
  use Ecto.Migration

  def change do
    create table(:listings) do
      add :title, :string, null: false
      add :description, :text
      add :starting_price, :decimal, null: false
      add :current_price, :decimal, null: false
      add :ends_at, :utc_datetime, null: false
      add :status, :string, null: false, default: "active"

      timestamps(type: :utc_datetime)
    end

    create index(:listings, [:status])
  end
end
