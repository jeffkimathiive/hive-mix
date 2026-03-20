defmodule Vebay.Repo.Migrations.CreateBids do
  use Ecto.Migration

  def change do
    create table(:bids) do
      add :bidder_name, :string, null: false
      add :amount, :decimal, null: false
      add :listing_id, references(:listings, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:bids, [:listing_id])
  end
end
