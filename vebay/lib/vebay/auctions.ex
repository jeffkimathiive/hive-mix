defmodule Vebay.Auctions do
  import Ecto.Query
  alias Vebay.Repo
  alias Vebay.Auctions.{Listing, Bid}

  # Listings

  def list_listings do
    Repo.all(from l in Listing, order_by: [asc: l.ends_at])
  end

  def get_listing!(id) do
    Listing
    |> Repo.get!(id)
    |> Repo.preload(bids: from(b in Bid, order_by: [desc: b.inserted_at], limit: 10))
  end

  def create_listing(attrs) do
    attrs = Map.put(attrs, "current_price", attrs["starting_price"] || attrs[:starting_price])

    %Listing{}
    |> Listing.changeset(attrs)
    |> Repo.insert()
  end

  # Bids

  def place_bid(listing_id, attrs) do
    Repo.transaction(fn ->
      listing = Repo.get!(Listing, listing_id)

      if listing.status == "closed" do
        Repo.rollback("Auction is closed")
      end

      amount = Decimal.new("#{attrs["amount"] || attrs[:amount]}")

      if Decimal.compare(amount, listing.current_price) != :gt do
        Repo.rollback("Bid must exceed current price of #{listing.current_price}")
      end

      bid_attrs = Map.merge(attrs, %{"listing_id" => listing_id})

      case %Bid{} |> Bid.changeset(bid_attrs) |> Repo.insert() do
        {:ok, bid} ->
          listing
          |> Ecto.Changeset.change(current_price: amount)
          |> Repo.update!()

          Phoenix.PubSub.broadcast(
            Vebay.PubSub,
            "listing:#{listing_id}",
            {:bid_placed, bid}
          )

          bid

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end
end
