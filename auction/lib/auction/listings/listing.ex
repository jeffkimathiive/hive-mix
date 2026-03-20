defmodule Auction.Listings.Listing do
  use Ecto.Schema
  import Ecto.Changeset

  schema "listings" do
    field :title, :string
    field :description, :string
    field :starting_price, :integer
    field :current_price, :integer
    field :end_time, :utc_datetime
    field :status, :string, default: "active"

    has_many :bids, Auction.Listings.Bid

    timestamps()
  end

  def changeset(listing, attrs) do
    listing
    |> cast(attrs, [:title, :description, :starting_price, :current_price, :end_time, :status])
    |> validate_required([:title, :starting_price, :current_price, :end_time])
  end
end
