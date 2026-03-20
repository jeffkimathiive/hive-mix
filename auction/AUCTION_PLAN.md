# Phoenix LiveView Auction System

## Overview

A single-page real-time auction system built with Phoenix LiveView. Users visit "/", see prepopulated listings with live countdown timers, place bids (no authentication), and when a listing's timer expires the highest bid wins.

## Architecture

```
Browser (LiveView)  ──→  Auction.Listings (Context)  ──→  Ecto / PostgreSQL
       ↑                         │
       └──── Phoenix.PubSub ←────┘
```

- **LiveView** handles the UI at "/" - streams listing cards, bid forms, countdowns
- **PubSub** broadcasts listing updates so all connected browsers stay in sync
- **ExpiryWorker** GenServer polls every 1 second to close expired listings
- **Colocated JS Hook** runs countdown timers client-side (no server ticks)

## Data Model

### Listings
| Field | Type | Notes |
|-------|------|-------|
| title | string | required |
| description | text | optional |
| starting_price | integer | cents, required |
| current_price | integer | cents, tracks highest bid |
| end_time | utc_datetime | when auction expires |
| status | string | "active" or "closed" |

### Bids
| Field | Type | Notes |
|-------|------|-------|
| listing_id | references | belongs_to listing |
| bidder_name | string | required |
| amount | integer | cents, must exceed current_price |

Prices are stored as integer cents to avoid floating point issues.

## Key Files

| File | Purpose |
|------|---------|
| `lib/auction/listings.ex` | Context - list_listings, place_bid, close_expired |
| `lib/auction/listings/listing.ex` | Listing Ecto schema |
| `lib/auction/listings/bid.ex` | Bid Ecto schema |
| `lib/auction/listings/expiry_worker.ex` | GenServer that closes expired auctions |
| `lib/auction_web/live/auction_live.ex` | LiveView - UI, bid handling, countdown hook |
| `lib/auction_web/router.ex` | Routes - `live "/", AuctionLive` |
| `lib/auction/application.ex` | Supervisor tree (includes ExpiryWorker) |
| `priv/repo/seeds.exs` | 4 sample listings with varying end times |

## How It Works

1. **Page Load**: LiveView mounts, loads all listings via `list_listings/0`, subscribes to PubSub topic `"listings"`
2. **Countdown**: Each listing card has a colocated JS hook that reads `data-end-time` and ticks every second client-side
3. **Placing a Bid**: Form submits `place_bid` event → context validates (active? not expired? bid > current price?) → inserts bid + updates listing in a transaction → broadcasts via PubSub
4. **Real-time Updates**: PubSub broadcast triggers `handle_info` → `stream_insert` updates just that one listing card for all connected browsers
5. **Expiry**: ExpiryWorker checks every second for active listings past their end_time, sets them to "closed", broadcasts the update → UI shows winner

## Running

```bash
mix ecto.reset      # create db, migrate, seed
mix phx.server      # start at http://localhost:4000
```

## Testing Checklist

- [ ] Visit http://localhost:4000 - see 4 listing cards with ticking countdowns
- [ ] Place a bid - price updates in real-time across all browser tabs
- [ ] Bid below current price - see error flash
- [ ] Wait for the 5-minute listing (Antique Pocket Watch) to expire - shows "Closed" with winner
- [ ] Open multiple browser tabs - verify bids sync across all tabs
