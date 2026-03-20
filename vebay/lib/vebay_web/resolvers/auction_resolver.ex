defmodule VebayWeb.Resolvers.AuctionResolver do
  alias Vebay.Auctions

  def list_listings(_parent, _args, _resolution) do
    {:ok, Auctions.list_listings()}
  end

  def get_listing(_parent, %{id: id}, _resolution) do
    {:ok, Auctions.get_listing!(id)}
  rescue
    Ecto.NoResultsError -> {:error, "Listing not found"}
  end

  def create_listing(_parent, args, _resolution) do
    attrs = Map.new(args, fn {k, v} -> {Atom.to_string(k), v} end)

    case Auctions.create_listing(attrs) do
      {:ok, listing} -> {:ok, listing}
      {:error, changeset} -> {:error, format_errors(changeset)}
    end
  end

  def place_bid(_parent, %{listing_id: listing_id, bidder_name: bidder_name, amount: amount}, _resolution) do
    attrs = %{"bidder_name" => bidder_name, "amount" => amount}

    case Auctions.place_bid(listing_id, attrs) do
      {:ok, bid} -> {:ok, bid}
      {:error, reason} when is_binary(reason) -> {:error, reason}
      {:error, changeset} -> {:error, format_errors(changeset)}
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end
end
