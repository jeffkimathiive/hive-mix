defmodule Auction.Repo.Migrations.CreateListingsAndBids do
  use Ecto.Migration

  def change do
    create table(:listings) do
      add :title, :string, null: false
      add :description, :text
      add :starting_price, :integer, null: false
      add :current_price, :integer, null: false
      add :end_time, :utc_datetime, null: false
      add :status, :string, null: false, default: "active"

      timestamps()
    end

    create table(:bids) do
      add :listing_id, references(:listings, on_delete: :delete_all), null: false
      add :bidder_name, :string, null: false
      add :amount, :integer, null: false

      timestamps()
    end

    create index(:bids, [:listing_id])
  end
end
