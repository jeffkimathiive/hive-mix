import { gql } from '@apollo/client/core'

export const GET_LISTINGS = gql`
  query GetListings {
    listings {
      id
      title
      description
      startingPrice
      currentPrice
      endsAt
      status
    }
  }
`

export const GET_LISTING = gql`
  query GetListing($id: ID!) {
    listing(id: $id) {
      id
      title
      description
      startingPrice
      currentPrice
      endsAt
      status
      bids {
        id
        bidderName
        amount
        insertedAt
      }
    }
  }
`

export const CREATE_LISTING = gql`
  mutation CreateListing($title: String!, $description: String, $startingPrice: Decimal!, $endsAt: String!) {
    createListing(title: $title, description: $description, startingPrice: $startingPrice, endsAt: $endsAt) {
      id
      title
      currentPrice
      status
    }
  }
`

export const PLACE_BID = gql`
  mutation PlaceBid($listingId: ID!, $bidderName: String!, $amount: Decimal!) {
    placeBid(listingId: $listingId, bidderName: $bidderName, amount: $amount) {
      id
      bidderName
      amount
      insertedAt
    }
  }
`

export const BID_PLACED_SUBSCRIPTION = gql`
  subscription BidPlaced($listingId: ID!) {
    bidPlaced(listingId: $listingId) {
      id
      bidderName
      amount
      insertedAt
    }
  }
`
