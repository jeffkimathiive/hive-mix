defmodule Auction.Listings.ExpiryWorker do
  use GenServer

  @interval :timer.seconds(1)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    schedule_check()
    {:ok, state}
  end

  @impl true
  def handle_info(:check_expired, state) do
    Auction.Listings.close_expired_listings()
    schedule_check()
    {:noreply, state}
  end

  defp schedule_check do
    Process.send_after(self(), :check_expired, @interval)
  end
end
