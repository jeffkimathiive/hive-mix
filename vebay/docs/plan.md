# Vebay Auction Service — Implementation Plan

> **Canonical location:** `vebay/doc/plan.md` (this file will be copied there during implementation)

## Context

Building a simple instructional auction service (eBay-like). No auth required.

**Architecture:** Phoenix acts as a pure GraphQL API server. A separate React/Vite app is the frontend. Phoenix Channels power real-time GraphQL subscriptions via Absinthe.

**Tech stack:**
- **Backend:** Phoenix + Absinthe (GraphQL) + PostgreSQL + Phoenix Channels (for subscriptions)
- **Frontend:** React + Vite + Apollo Client (or urql) — separate app in `frontend/`
- **Styling:** Tailwind CSS v4 (in React app)
- **No LiveView** — UI is entirely client-side React

---

## Models

### `Listing`
| Column | Type | Notes |
|---|---|---|
| `id` | bigint (PK) | |
| `title` | string | |
| `description` | text | |
| `starting_price` | decimal | |
| `current_price` | decimal | updated on each bid |
| `ends_at` | utc_datetime | when the auction closes |
| `status` | string | `"active"` \| `"closed"` |
| timestamps | | |

### `Bid`
| Column | Type | Notes |
|---|---|---|
| `id` | bigint (PK) | |
| `bidder_name` | string | no auth, just a name |
| `amount` | decimal | must exceed `current_price` |
| `listing_id` | FK → listings | |
| timestamps | | |

---

## Backend Implementation Steps

### 1. Add Absinthe dependencies — `mix.exs`
```elixir
{:absinthe, "~> 1.7"},
{:absinthe_phoenix, "~> 2.0"},
{:absinthe_plug, "~> 1.5"},
{:corsica, "~> 2.1"},   # allow React dev server (localhost:5173)
```

### 2. Migrations — `priv/repo/migrations/`
- `create_listings` — all columns above
- `create_bids` — all columns above, FK with `on_delete: :delete_all`

### 3. Ecto Schemas
- `lib/vebay/auctions/listing.ex` — schema + changeset
- `lib/vebay/auctions/bid.ex` — schema + changeset (validate `amount > current_price`)

### 4. Context — `lib/vebay/auctions.ex`
- `list_listings/0`
- `get_listing!/1` — preload recent bids
- `create_listing/1` — sets `current_price = starting_price`, `status = "active"`
- `place_bid/2` — validates amount, updates `current_price` in a transaction, publishes PubSub event

### 5. GraphQL Schema — `lib/vebay_web/schema.ex`

**Types:** `:listing`, `:bid`

**Queries:**
- `listings` → all active listings
- `listing(id)` → single listing with bids

**Mutations:**
- `create_listing(title, description, starting_price, ends_at)` → Listing
- `place_bid(listing_id, bidder_name, amount)` → Bid

**Subscriptions:**
- `bid_placed(listing_id)` → pushed to all subscribers when a bid is placed

### 6. Resolver — `lib/vebay_web/resolvers/auction_resolver.ex`
Thin wrapper calling `Vebay.Auctions` context functions.

### 7. Phoenix Channel (Absinthe WebSocket) — `lib/vebay_web/user_socket.ex`

Absinthe Phoenix adds an `__absinthe__:control` channel automatically. Wire it up:

```elixir
# endpoint.ex
socket "/socket", VebayWeb.UserSocket,
  websocket: true,
  longpoll: false

# user_socket.ex
use Phoenix.Socket
use Absinthe.Phoenix.Socket, schema: VebayWeb.Schema
```

### 8. CORS — `lib/vebay_web/endpoint.ex`
```elixir
plug Corsica,
  origins: ["http://localhost:5173"],
  allow_headers: ["content-type"]
```

### 9. Router — `lib/vebay_web/router.ex`
```elixir
scope "/api" do
  pipe_through :api
  forward "/graphql", Absinthe.Plug, schema: VebayWeb.Schema
  forward "/graphiql", Absinthe.Plug.GraphiQL,
    schema: VebayWeb.Schema,
    socket: VebayWeb.UserSocket   # enables subscription playground
end
```

Remove the LiveView `/` route; Phoenix only serves the API.

### 10. Seeds — `priv/repo/seeds.exs`
Insert 3–4 sample listings with varying end times.

---

## Frontend Implementation Steps (`frontend/`)

### Bootstrap
```bash
npm create vite@latest frontend -- --template react
cd frontend && npm install
npm install -D tailwindcss @tailwindcss/vite
npm install @apollo/client graphql graphql-ws
```

### Key files
- `frontend/src/main.jsx` — ApolloProvider wrapping the app, pointing to `http://localhost:4000/api/graphql` (HTTP) and `ws://localhost:4000/socket` (WS for subscriptions)
- `frontend/src/App.jsx` — single-page layout: listing sidebar + detail/bid panel
- `frontend/src/graphql/` — query/mutation/subscription documents

### Single-page layout
- **Left panel:** `listings` query → list cards (title, current price, countdown)
- **Right panel:** selected listing detail + `place_bid` mutation form
- **Real-time:** `bid_placed` subscription updates the current price live

---

## Files to Create/Modify

### Phoenix (backend)
| File | Action |
|---|---|
| `mix.exs` | Add absinthe + corsica deps |
| `priv/repo/migrations/*_create_listings.exs` | Create |
| `priv/repo/migrations/*_create_bids.exs` | Create |
| `lib/vebay/auctions/listing.ex` | Create |
| `lib/vebay/auctions/bid.ex` | Create |
| `lib/vebay/auctions.ex` | Create |
| `lib/vebay_web/schema.ex` | Create |
| `lib/vebay_web/resolvers/auction_resolver.ex` | Create |
| `lib/vebay_web/user_socket.ex` | Create |
| `lib/vebay_web/endpoint.ex` | Add socket + CORS |
| `lib/vebay_web/router.ex` | Add GraphQL routes, remove LiveView |
| `priv/repo/seeds.exs` | Add sample listings |
| `doc/plan.md` | Copy this plan here |

### React (frontend)
| File | Action |
|---|---|
| `frontend/` | Scaffold via Vite |
| `frontend/src/main.jsx` | Apollo Client setup |
| `frontend/src/App.jsx` | Single-page UI |
| `frontend/src/graphql/*.js` | GQL documents |

---

## Verification

1. `mix deps.get && mix ecto.migrate` — DB tables created
2. `mix run priv/repo/seeds.exs` — sample data loaded
3. `mix phx.server` (port 4000)
4. Visit `http://localhost:4000/api/graphiql` — run `listings` query and `bid_placed` subscription
5. `cd frontend && npm run dev` (port 5173) — React app loads
6. Place a bid in React → price updates live via subscription
7. `mix test`
