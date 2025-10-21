# BidX Smart Contract

## Overview

BidX is a decentralized English auction platform that enables users to create, manage, and participate in time-limited auctions for digital assets. It ensures transparent bidding, automatic fund handling through escrow, and secure auction finalization.

## Features

* **Auction Creation:** Sellers can list items with a starting price and defined duration.
* **Dynamic Bidding:** Participants place bids with automatic validation of minimum increments.
* **Escrow System:** Bid amounts are held in contract escrow until auction resolution.
* **Auction Management:** Sellers can extend, cancel, or finalize auctions.
* **Proceeds Claiming:** Sellers claim funds after successful auctions.
* **Read-only Data Access:** View auction details, bid history, and minimum next bid.

## Functions

### Auction Management

* `create-auction(item-name, description, starting-price, duration)`
  Creates a new auction with the specified parameters.

* `end-auction(auction-id)`
  Ends an active auction after its duration expires.

* `extend-auction(auction-id, additional-blocks)`
  Extends the auction time (seller-only, before expiration).

* `cancel-auction(auction-id)`
  Cancels an auction if no bids have been placed.

### Bidding System

* `place-bid(auction-id, bid-amount)`
  Places a new bid on an active auction, ensuring bid amount exceeds the current highest plus the minimum increment.

### Settlement

* `claim-proceeds(auction-id)`
  Allows the seller to claim proceeds after a successful auction.

### Read-only Queries

* `get-auction(auction-id)` Retrieves auction details.
* `get-bid(auction-id, bidder)` Retrieves a specific bidder’s data.
* `get-bid-history(auction-id, bid-number)` Returns bid records chronologically.
* `get-auction-count()` Returns total auctions created.
* `is-auction-active(auction-id)` Checks auction activity status.
* `get-time-remaining(auction-id)` Returns blocks remaining until auction end.
* `get-minimum-bid(auction-id)` Calculates next valid bid threshold.
* `can-end-auction(auction-id)` Confirms if auction can be ended.

## Access Control

* Only the seller can extend, cancel, or claim auction proceeds.
* Any user can place bids and end expired auctions.

## Error Codes

* `ERR-AUCTION-NOT-FOUND (u800)` Invalid auction ID.
* `ERR-AUCTION-ENDED (u801)` Auction has ended.
* `ERR-BID-TOO-LOW (u802)` Bid below minimum threshold.
* `ERR-NOT-AUTHORIZED (u803)` Unauthorized action.
* `ERR-AUCTION-ACTIVE (u804)` Auction still active.
* `ERR-NO-BIDS (u805)` No bids placed.
* `ERR-ALREADY-CLAIMED (u806)` Proceeds already claimed.
* `ERR-INVALID-DURATION (u807)` Invalid or excessive duration.

## Governance

* Auctions are fully managed by sellers.
* Platform ensures trustless fund handling and transparent auction lifecycles.
