alias Auction.Repo
alias Auction.Listings.Listing

now = DateTime.utc_now()

listings = [
  %{
    title: "Vintage Mechanical Keyboard",
    description: "IBM Model M from 1989, excellent condition with original cable",
    starting_price: 5000,
    current_price: 5000,
    end_time: DateTime.add(now, 2 * 3600, :second) |> DateTime.truncate(:second)
  },
  %{
    title: "Rare Vinyl Record",
    description: "First pressing of a classic album, near mint condition",
    starting_price: 2500,
    current_price: 2500,
    end_time: DateTime.add(now, 3600, :second) |> DateTime.truncate(:second)
  },
  %{
    title: "Antique Pocket Watch",
    description: "Swiss-made, circa 1920, fully functional",
    starting_price: 15000,
    current_price: 15000,
    end_time: DateTime.add(now, 5 * 60, :second) |> DateTime.truncate(:second)
  },
  %{
    title: "Signed First Edition Book",
    description: "Hardcover with author signature, dust jacket intact",
    starting_price: 7500,
    current_price: 7500,
    end_time: DateTime.add(now, 24 * 3600, :second) |> DateTime.truncate(:second)
  }
]

for attrs <- listings do
  %Listing{}
  |> Listing.changeset(attrs)
  |> Repo.insert!()
end
