import { useState } from 'react'
import { useQuery, useMutation, useSubscription } from '@apollo/client/react'
import { GET_LISTINGS, GET_LISTING, CREATE_LISTING, PLACE_BID, BID_PLACED_SUBSCRIPTION } from './graphql/operations'

function formatPrice(price) {
  return `$${parseFloat(price).toLocaleString('en-US', { minimumFractionDigits: 2 })}`
}

function timeLeft(endsAt) {
  const diff = new Date(endsAt) - new Date()
  if (diff <= 0) return 'Ended'
  const d = Math.floor(diff / 86400000)
  const h = Math.floor((diff % 86400000) / 3600000)
  const m = Math.floor((diff % 3600000) / 60000)
  if (d > 0) return `${d}d ${h}h left`
  if (h > 0) return `${h}h ${m}m left`
  return `${m}m left`
}

function ListingCard({ listing, selected, onSelect }) {
  return (
    <button
      onClick={() => onSelect(listing.id)}
      className={`w-full text-left p-4 rounded-lg border transition-colors ${
        selected
          ? 'border-blue-500 bg-blue-50'
          : 'border-gray-200 hover:border-gray-300 bg-white'
      }`}
    >
      <div className="font-semibold text-gray-900 truncate">{listing.title}</div>
      <div className="mt-1 flex justify-between items-center">
        <span className="text-lg font-bold text-blue-600">{formatPrice(listing.currentPrice)}</span>
        <span className={`text-xs px-2 py-1 rounded-full ${
          listing.status === 'active' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'
        }`}>
          {listing.status === 'active' ? timeLeft(listing.endsAt) : 'Closed'}
        </span>
      </div>
    </button>
  )
}

function BidList({ bids }) {
  if (!bids || bids.length === 0) {
    return <p className="text-gray-400 text-sm italic">No bids yet. Be the first!</p>
  }
  return (
    <ul className="space-y-2">
      {bids.map(bid => (
        <li key={bid.id} className="flex justify-between text-sm border-b border-gray-100 pb-2">
          <span className="font-medium text-gray-700">{bid.bidderName}</span>
          <span className="text-blue-600 font-bold">{formatPrice(bid.amount)}</span>
        </li>
      ))}
    </ul>
  )
}

function ListingDetail({ listingId, onClose }) {
  const [bidderName, setBidderName] = useState('')
  const [amount, setAmount] = useState('')
  const [error, setError] = useState(null)
  const [success, setSuccess] = useState(null)

  const { data, loading, refetch } = useQuery(GET_LISTING, { variables: { id: listingId } })

  useSubscription(BID_PLACED_SUBSCRIPTION, {
    variables: { listingId },
    onData: () => refetch(),
  })

  const [placeBid, { loading: bidding }] = useMutation(PLACE_BID, {
    onCompleted: () => {
      setSuccess('Bid placed!')
      setBidderName('')
      setAmount('')
      setError(null)
      refetch()
      setTimeout(() => setSuccess(null), 3000)
    },
    onError: (err) => {
      setError(err.message)
      setSuccess(null)
    },
  })

  if (loading) return <div className="p-8 text-gray-400">Loading...</div>
  const listing = data?.listing
  if (!listing) return null

  const handleBid = (e) => {
    e.preventDefault()
    setError(null)
    placeBid({ variables: { listingId, bidderName, amount } })
  }

  return (
    <div className="flex flex-col h-full">
      <div className="flex justify-between items-start mb-4">
        <h2 className="text-xl font-bold text-gray-900">{listing.title}</h2>
        <button onClick={onClose} className="text-gray-400 hover:text-gray-600 text-xl leading-none">&times;</button>
      </div>

      {listing.description && (
        <p className="text-gray-600 text-sm mb-4">{listing.description}</p>
      )}

      <div className="flex gap-6 mb-6 p-4 bg-gray-50 rounded-lg">
        <div>
          <div className="text-xs text-gray-500 uppercase tracking-wide">Starting</div>
          <div className="font-semibold text-gray-700">{formatPrice(listing.startingPrice)}</div>
        </div>
        <div>
          <div className="text-xs text-gray-500 uppercase tracking-wide">Current</div>
          <div className="text-xl font-bold text-blue-600">{formatPrice(listing.currentPrice)}</div>
        </div>
        <div>
          <div className="text-xs text-gray-500 uppercase tracking-wide">Time Left</div>
          <div className="font-semibold text-gray-700">{timeLeft(listing.endsAt)}</div>
        </div>
      </div>

      {listing.status === 'active' && (
        <form onSubmit={handleBid} className="mb-6 p-4 border border-gray-200 rounded-lg">
          <h3 className="font-semibold text-gray-800 mb-3">Place a Bid</h3>
          <div className="flex gap-2 mb-3">
            <input
              className="flex-1 border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400"
              placeholder="Your name"
              value={bidderName}
              onChange={e => setBidderName(e.target.value)}
              required
            />
            <input
              className="w-32 border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400"
              placeholder="Amount"
              type="number"
              step="0.01"
              min="0"
              value={amount}
              onChange={e => setAmount(e.target.value)}
              required
            />
          </div>
          {error && <p className="text-red-500 text-xs mb-2">{error}</p>}
          {success && <p className="text-green-600 text-xs mb-2">{success}</p>}
          <button
            type="submit"
            disabled={bidding}
            className="w-full bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white font-semibold py-2 px-4 rounded transition-colors"
          >
            {bidding ? 'Placing...' : 'Place Bid'}
          </button>
        </form>
      )}

      <div>
        <h3 className="font-semibold text-gray-800 mb-3">Recent Bids</h3>
        <BidList bids={listing.bids} />
      </div>
    </div>
  )
}

function CreateListingModal({ onClose, onCreated }) {
  const [form, setForm] = useState({ title: '', description: '', startingPrice: '', endsAt: '' })
  const [error, setError] = useState(null)

  const [createListing, { loading }] = useMutation(CREATE_LISTING, {
    onCompleted: () => { onCreated(); onClose() },
    onError: (err) => setError(err.message),
  })

  const handleSubmit = (e) => {
    e.preventDefault()
    createListing({
      variables: {
        title: form.title,
        description: form.description || null,
        startingPrice: form.startingPrice,
        endsAt: new Date(form.endsAt).toISOString(),
      },
    })
  }

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl shadow-xl p-6 w-full max-w-md">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-lg font-bold text-gray-900">Create Listing</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 text-xl">&times;</button>
        </div>
        <form onSubmit={handleSubmit} className="space-y-3">
          <input
            className="w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400"
            placeholder="Title"
            value={form.title}
            onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
            required
          />
          <textarea
            className="w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400"
            placeholder="Description (optional)"
            rows={3}
            value={form.description}
            onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
          />
          <input
            className="w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400"
            placeholder="Starting price"
            type="number"
            step="0.01"
            min="0"
            value={form.startingPrice}
            onChange={e => setForm(f => ({ ...f, startingPrice: e.target.value }))}
            required
          />
          <input
            className="w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400"
            type="datetime-local"
            value={form.endsAt}
            onChange={e => setForm(f => ({ ...f, endsAt: e.target.value }))}
            required
          />
          {error && <p className="text-red-500 text-xs">{error}</p>}
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white font-semibold py-2 px-4 rounded transition-colors"
          >
            {loading ? 'Creating...' : 'Create Listing'}
          </button>
        </form>
      </div>
    </div>
  )
}

export default function App() {
  const [selectedId, setSelectedId] = useState(null)
  const [showCreate, setShowCreate] = useState(false)

  const { data, loading, refetch } = useQuery(GET_LISTINGS, {
    pollInterval: 30000,
  })

  const listings = data?.listings ?? []

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b border-gray-200 px-6 py-4 flex justify-between items-center">
        <h1 className="text-2xl font-bold text-blue-600">vebay</h1>
        <button
          onClick={() => setShowCreate(true)}
          className="bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold px-4 py-2 rounded-lg transition-colors"
        >
          + New Listing
        </button>
      </header>

      <div className="flex h-[calc(100vh-65px)]">
        {/* Listings sidebar */}
        <aside className="w-80 flex-shrink-0 border-r border-gray-200 bg-white overflow-y-auto p-4 space-y-3">
          <h2 className="text-xs font-semibold text-gray-500 uppercase tracking-widest mb-3">
            Active Auctions ({listings.length})
          </h2>
          {loading && <p className="text-gray-400 text-sm">Loading...</p>}
          {listings.map(listing => (
            <ListingCard
              key={listing.id}
              listing={listing}
              selected={listing.id === selectedId}
              onSelect={setSelectedId}
            />
          ))}
        </aside>

        {/* Detail panel */}
        <main className="flex-1 overflow-y-auto p-8">
          {selectedId ? (
            <ListingDetail
              listingId={selectedId}
              onClose={() => setSelectedId(null)}
            />
          ) : (
            <div className="flex items-center justify-center h-full text-gray-400">
              <div className="text-center">
                <div className="text-5xl mb-4">🔨</div>
                <p className="text-lg">Select an auction to place a bid</p>
              </div>
            </div>
          )}
        </main>
      </div>

      {showCreate && (
        <CreateListingModal
          onClose={() => setShowCreate(false)}
          onCreated={refetch}
        />
      )}
    </div>
  )
}
