defmodule AuctionWeb.AuctionLive do
  use AuctionWeb, :live_view

  alias Auction.Listings
  alias AuctionWeb.Layouts

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Auction.PubSub, "listings")
    end

    listings = Listings.list_listings()

    socket =
      socket
      |> stream(:listings, listings)
      |> assign(:bid_form, to_form(Listings.change_bid(), as: :bid))

    {:ok, socket}
  end

  @impl true
  def handle_info({:listing_updated, listing}, socket) do
    {:noreply, stream_insert(socket, :listings, listing)}
  end

  @impl true
  def handle_event("place_bid", %{"bid" => bid_params}, socket) do
    listing_id = bid_params["listing_id"]

    amount =
      case Integer.parse(bid_params["amount"] || "") do
        {val, _} -> val
        :error -> 0
      end

    case Listings.place_bid(listing_id, %{
           bidder_name: bid_params["bidder_name"],
           amount: amount
         }) do
      {:ok, _listing} ->
        socket =
          socket
          |> put_flash(:info, "Bid placed successfully!")
          |> assign(:bid_form, to_form(Listings.change_bid(), as: :bid))

        {:noreply, socket}

      {:error, reason} when is_binary(reason) ->
        {:noreply, put_flash(socket, :error, reason)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Invalid bid")}
    end
  end

  defp winner(%{bids: bids, status: "closed"}) when bids != [] do
    Enum.max_by(bids, & &1.amount)
  end

  defp winner(_), do: nil

  defp format_price(cents) do
    dollars = div(cents, 100)
    remainder = rem(cents, 100)
    "$#{dollars}.#{String.pad_leading(Integer.to_string(remainder), 2, "0")}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".Countdown">
        export default {
          mounted() {
            this.endTime = new Date(this.el.dataset.endTime + "Z").getTime()
            this.status = this.el.dataset.status
            this.tick()
            this.timer = setInterval(() => this.tick(), 1000)
          },
          updated() {
            this.endTime = new Date(this.el.dataset.endTime + "Z").getTime()
            this.status = this.el.dataset.status
            if (this.status === "closed") {
              clearInterval(this.timer)
              this.el.textContent = "Closed"
              this.el.className = "badge badge-error"
            }
          },
          destroyed() {
            if (this.timer) clearInterval(this.timer)
          },
          tick() {
            if (this.status === "closed") {
              this.el.textContent = "Closed"
              this.el.className = "badge badge-error"
              clearInterval(this.timer)
              return
            }
            const now = Date.now()
            const diff = this.endTime - now
            if (diff <= 0) {
              this.el.textContent = "Ending..."
              this.el.className = "badge badge-warning"
              clearInterval(this.timer)
              return
            }
            const h = Math.floor(diff / 3600000)
            const m = Math.floor((diff % 3600000) / 60000)
            const s = Math.floor((diff % 60000) / 1000)
            this.el.textContent = `${h}h ${m}m ${s}s`
            this.el.className = "badge badge-info"
          }
        }
      </script>

      <h1 class="text-3xl font-bold text-center mb-8">Live Auctions</h1>

      <div id="listings" phx-update="stream" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div :for={{dom_id, listing} <- @streams.listings} id={dom_id} class="card bg-base-200 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">{listing.title}</h2>
            <p class="text-sm opacity-70">{listing.description}</p>

            <div class="flex justify-between items-center mt-2">
              <div>
                <div class="text-xs opacity-50">Current Price</div>
                <div class="text-xl font-bold">{format_price(listing.current_price)}</div>
              </div>
              <span
                id={"countdown-#{listing.id}"}
                phx-hook=".Countdown"
                data-end-time={Calendar.strftime(listing.end_time, "%Y-%m-%dT%H:%M:%S")}
                data-status={listing.status}
                class="badge badge-info"
              >
              </span>
            </div>

            <%= if listing.status == "active" do %>
              <.form for={@bid_form} id={"bid-form-#{listing.id}"} phx-submit="place_bid" class="mt-4 flex flex-col gap-2">
                <input type="hidden" name="bid[listing_id]" value={listing.id} />
                <.input field={@bid_form[:bidder_name]} type="text" placeholder="Your name" />
                <.input
                  field={@bid_form[:amount]}
                  type="number"
                  placeholder={"Min bid: #{format_price(listing.current_price + 1)}"}
                  min={listing.current_price + 1}
                />
                <button type="submit" class="btn btn-primary btn-sm">Place Bid</button>
              </.form>
            <% else %>
              <div class="mt-4 p-3 bg-base-300 rounded-lg">
                <div class="text-sm font-semibold text-error">Auction Closed</div>
                <%= if w = winner(listing) do %>
                  <div class="text-sm mt-1">
                    Winner: <span class="font-bold">{w.bidder_name}</span>
                    with a bid of <span class="font-bold">{format_price(w.amount)}</span>
                  </div>
                <% else %>
                  <div class="text-sm mt-1 opacity-50">No bids were placed</div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
