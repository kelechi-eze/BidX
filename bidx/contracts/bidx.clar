;; English Auction Contract
;; A decentralized auction platform for digital assets

;; Error constants
(define-constant ERR-AUCTION-NOT-FOUND (err u800))
(define-constant ERR-AUCTION-ENDED (err u801))
(define-constant ERR-BID-TOO-LOW (err u802))
(define-constant ERR-NOT-AUTHORIZED (err u803))
(define-constant ERR-AUCTION-ACTIVE (err u804))
(define-constant ERR-NO-BIDS (err u805))
(define-constant ERR-ALREADY-CLAIMED (err u806))
(define-constant ERR-INVALID-DURATION (err u807))

;; Constants
(define-constant AUCTION-ACTIVE u0)
(define-constant AUCTION-ENDED u1)
(define-constant AUCTION-CLAIMED u2)
(define-constant MIN-BID-INCREMENT u100000) ;; 0.1 STX minimum increment

;; Data variables
(define-data-var auction-counter uint u0)

;; Data maps
(define-map auctions
  { auction-id: uint }
  {
    seller: principal,
    item-name: (string-utf8 100),
    description: (string-utf8 300),
    starting-price: uint,
    current-bid: uint,
    highest-bidder: (optional principal),
    end-block: uint,
    status: uint,
    created-at: uint,
    bid-count: uint
  }
)

(define-map bids
  { auction-id: uint, bidder: principal }
  {
    amount: uint,
    timestamp: uint,
    outbid: bool
  }
)

(define-map bid-history
  { auction-id: uint, bid-number: uint }
  {
    bidder: principal,
    amount: uint,
    timestamp: uint
  }
)

(define-map escrow-balances
  { auction-id: uint, bidder: principal }
  { amount: uint }
)

;; Create a new auction
(define-public (create-auction 
  (item-name (string-utf8 100))
  (description (string-utf8 300))
  (starting-price uint)
  (duration uint)
)
  (let
    (
      (auction-id (+ (var-get auction-counter) u1))
      (end-block (+ block-height duration))
    )
    (asserts! (> starting-price u0) ERR-BID-TOO-LOW)
    (asserts! (> duration u0) ERR-INVALID-DURATION)
    (asserts! (<= duration u52560) ERR-INVALID-DURATION) ;; Max 1 year
    
    (map-set auctions
      { auction-id: auction-id }
      {
        seller: tx-sender,
        item-name: item-name,
        description: description,
        starting-price: starting-price,
        current-bid: starting-price,
        highest-bidder: none,
        end-block: end-block,
        status: AUCTION-ACTIVE,
        created-at: block-height,
        bid-count: u0
      }
    )
    
    (var-set auction-counter auction-id)
    (ok auction-id)
  )
)

;; Place a bid
(define-public (place-bid (auction-id uint) (bid-amount uint))
  (let
    (
      (auction-data (unwrap! (map-get? auctions { auction-id: auction-id }) ERR-AUCTION-NOT-FOUND))
      (current-highest (get current-bid auction-data))
      (min-bid (+ current-highest MIN-BID-INCREMENT))
      (previous-bidder (get highest-bidder auction-data))
      (existing-bid (map-get? bids { auction-id: auction-id, bidder: tx-sender }))
      (bid-number (+ (get bid-count auction-data) u1))
    )
    (asserts! (is-eq (get status auction-data) AUCTION-ACTIVE) ERR-AUCTION-ENDED)
    (asserts! (<= block-height (get end-block auction-data)) ERR-AUCTION-ENDED)
    (asserts! (>= bid-amount min-bid) ERR-BID-TOO-LOW)
    (asserts! (not (is-eq tx-sender (get seller auction-data))) ERR-NOT-AUTHORIZED)
    (asserts! (>= (stx-get-balance tx-sender) bid-amount) ERR-BID-TOO-LOW)
    
    ;; Transfer bid amount to contract escrow
    (try! (stx-transfer? bid-amount tx-sender (as-contract tx-sender)))
    
    ;; <CHANGE> Return previous bid to previous highest bidder - use 'pb' to avoid shadowing
    (match previous-bidder
      pb 
        (try! (as-contract (stx-transfer? current-highest tx-sender pb)))
      true
    )
    
    ;; <CHANGE> Mark previous bidder as outbid - use 'pb' to avoid shadowing
    (match previous-bidder
      pb
        (match (map-get? bids { auction-id: auction-id, bidder: pb })
          prev-bid-data
            (map-set bids
              { auction-id: auction-id, bidder: pb }
              (merge prev-bid-data { outbid: true })
            )
          true
        )
      true
    )
    
    ;; Record new bid
    (map-set bids
      { auction-id: auction-id, bidder: tx-sender }
      {
        amount: bid-amount,
        timestamp: block-height,
        outbid: false
      }
    )
    
    ;; Record in bid history
    (map-set bid-history
      { auction-id: auction-id, bid-number: bid-number }
      {
        bidder: tx-sender,
        amount: bid-amount,
        timestamp: block-height
      }
    )
    
    ;; Update auction data
    (map-set auctions
      { auction-id: auction-id }
      (merge auction-data {
        current-bid: bid-amount,
        highest-bidder: (some tx-sender),
        bid-count: bid-number
      })
    )
    
    (ok true)
  )
)

;; ... existing code ...