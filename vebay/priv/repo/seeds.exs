# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Vebay.Repo.insert!(%Vebay.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Vebay.Repo
alias Vebay.Auctions.Listing

now = DateTime.utc_now()

listings = [
  %{
    title: "Vintage Gibson Les Paul 1959",
    description: "All original, collector's condition. A true piece of rock history.",
    starting_price: Decimal.new("4500.00"),
    current_price: Decimal.new("4500.00"),
    ends_at: DateTime.add(now, 3 * 24 * 3600, :second) |> DateTime.truncate(:second),
    status: "active"
  },
  %{
    title: "Original Apple Macintosh (1984)",
    description: "Working unit with original box and accessories. Beige beauty.",
    starting_price: Decimal.new("800.00"),
    current_price: Decimal.new("800.00"),
    ends_at: DateTime.add(now, 1 * 24 * 3600, :second) |> DateTime.truncate(:second),
    status: "active"
  },
  %{
    title: "Rolex Submariner 5513 (1968)",
    description: "Meters first dial, tropical patina. Service records included.",
    starting_price: Decimal.new("12000.00"),
    current_price: Decimal.new("12000.00"),
    ends_at: DateTime.add(now, 7 * 24 * 3600, :second) |> DateTime.truncate(:second),
    status: "active"
  },
  %{
    title: "1st Edition Harry Potter (1997)",
    description: "Bloomsbury first printing, first edition. Minor shelf wear.",
    starting_price: Decimal.new("2000.00"),
    current_price: Decimal.new("2000.00"),
    ends_at: DateTime.add(now, 2 * 24 * 3600, :second) |> DateTime.truncate(:second),
    status: "active"
  }
]

Enum.each(listings, fn attrs ->
  Repo.insert!(%Listing{} |> Ecto.Changeset.change(attrs))
end)

IO.puts("Seeded #{length(listings)} listings.")
