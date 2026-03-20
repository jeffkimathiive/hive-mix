defmodule Auction.Listings.Bid do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bids" do
    field :bidder_name, :string
    field :amount, :integer

    belongs_to :listing, Auction.Listings.Listing

    timestamps()
  end

  def changeset(bid, attrs) do
    bid
    |> cast(attrs, [:bidder_name, :amount])
    |> validate_required([:bidder_name, :amount])
    |> validate_number(:amount, greater_than: 0)
  end
end
