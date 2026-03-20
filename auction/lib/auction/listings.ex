defmodule Auction.Listings do
  import Ecto.Query
  alias Auction.Repo
  alias Auction.Listings.{Listing, Bid}

  def list_listings do
    Listing
    |> order_by([l], asc: l.end_time)
    |> preload(:bids)
    |> Repo.all()
  end

  def place_bid(listing_id, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:listing, fn repo, _ ->
      listing = repo.get!(Listing, listing_id) |> repo.preload(:bids)

      cond do
        listing.status != "active" ->
          {:error, "Auction is closed"}

        DateTime.compare(listing.end_time, DateTime.utc_now()) != :gt ->
          {:error, "Auction has expired"}

        true ->
          {:ok, listing}
      end
    end)
    |> Ecto.Multi.run(:validate_amount, fn _repo, %{listing: listing} ->
      amount = attrs[:amount] || attrs["amount"]

      if amount > listing.current_price do
        {:ok, amount}
      else
        {:error, "Bid must be higher than current price of #{listing.current_price}"}
      end
    end)
    |> Ecto.Multi.run(:bid, fn repo, %{listing: listing, validate_amount: amount} ->
      %Bid{listing_id: listing.id}
      |> Bid.changeset(%{bidder_name: attrs[:bidder_name] || attrs["bidder_name"], amount: amount})
      |> repo.insert()
    end)
    |> Ecto.Multi.run(:update_listing, fn repo, %{listing: listing, validate_amount: amount} ->
      listing
      |> Listing.changeset(%{current_price: amount})
      |> repo.update()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{update_listing: listing}} ->
        listing = Repo.preload(listing, :bids, force: true)
        Phoenix.PubSub.broadcast(Auction.PubSub, "listings", {:listing_updated, listing})
        {:ok, listing}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  def close_expired_listings do
    now = DateTime.utc_now()

    listings =
      Listing
      |> where([l], l.status == "active" and l.end_time < ^now)
      |> Repo.all()
      |> Repo.preload(:bids)

    Enum.each(listings, fn listing ->
      listing
      |> Listing.changeset(%{status: "closed"})
      |> Repo.update!()

      closed = %{listing | status: "closed"}
      Phoenix.PubSub.broadcast(Auction.PubSub, "listings", {:listing_updated, closed})
    end)
  end

  def change_bid(attrs \\ %{}) do
    Bid.changeset(%Bid{}, attrs)
  end
end
