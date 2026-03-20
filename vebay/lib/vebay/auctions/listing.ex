defmodule Vebay.Auctions.Listing do
  use Ecto.Schema
  import Ecto.Changeset

  schema "listings" do
    field :title, :string
    field :description, :string
    field :starting_price, :decimal
    field :current_price, :decimal
    field :ends_at, :utc_datetime
    field :status, :string, default: "active"

    has_many :bids, Vebay.Auctions.Bid

    timestamps(type: :utc_datetime)
  end

  def changeset(listing, attrs) do
    listing
    |> cast(attrs, [:title, :description, :starting_price, :current_price, :ends_at, :status])
    |> validate_required([:title, :starting_price, :ends_at])
    |> validate_number(:starting_price, greater_than: 0)
    |> validate_inclusion(:status, ["active", "closed"])
  end
end
