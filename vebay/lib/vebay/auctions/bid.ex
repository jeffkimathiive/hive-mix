defmodule Vebay.Auctions.Bid do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bids" do
    field :bidder_name, :string
    field :amount, :decimal

    belongs_to :listing, Vebay.Auctions.Listing

    timestamps(type: :utc_datetime)
  end

  def changeset(bid, attrs) do
    bid
    |> cast(attrs, [:bidder_name, :amount, :listing_id])
    |> validate_required([:bidder_name, :amount, :listing_id])
    |> validate_number(:amount, greater_than: 0)
  end
end
