defmodule VebayWeb.Schema do
  use Absinthe.Schema

  alias VebayWeb.Resolvers.AuctionResolver

  object :bid do
    field :id, :id
    field :bidder_name, :string
    field :amount, :decimal
    field :inserted_at, :string
  end

  object :listing do
    field :id, :id
    field :title, :string
    field :description, :string
    field :starting_price, :decimal
    field :current_price, :decimal
    field :ends_at, :string
    field :status, :string
    field :bids, list_of(:bid)
    field :inserted_at, :string
  end

  scalar :decimal do
    parse fn
      %Absinthe.Blueprint.Input.String{value: value} ->
        {:ok, Decimal.new(value)}
      %Absinthe.Blueprint.Input.Float{value: value} ->
        {:ok, Decimal.new("#{value}")}
      %Absinthe.Blueprint.Input.Integer{value: value} ->
        {:ok, Decimal.new(value)}
      _ ->
        :error
    end

    serialize fn value -> Decimal.to_string(value) end
  end

  query do
    field :listings, list_of(:listing) do
      resolve &AuctionResolver.list_listings/3
    end

    field :listing, :listing do
      arg :id, non_null(:id)
      resolve &AuctionResolver.get_listing/3
    end
  end

  mutation do
    field :create_listing, :listing do
      arg :title, non_null(:string)
      arg :description, :string
      arg :starting_price, non_null(:decimal)
      arg :ends_at, non_null(:string)
      resolve &AuctionResolver.create_listing/3
    end

    field :place_bid, :bid do
      arg :listing_id, non_null(:id)
      arg :bidder_name, non_null(:string)
      arg :amount, non_null(:decimal)
      resolve &AuctionResolver.place_bid/3
    end
  end

  subscription do
    field :bid_placed, :bid do
      arg :listing_id, non_null(:id)

      config fn args, _info ->
        {:ok, topic: "listing:#{args.listing_id}"}
      end

      trigger :place_bid, topic: fn bid ->
        "listing:#{bid.listing_id}"
      end
    end
  end
end
