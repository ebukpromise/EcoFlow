;; EcoFlow Energy Trading Contract
;; Clarity v2

(define-trait token-trait
  (
    ;; Transfer tokens: sender -> recipient
    (transfer (sender principal) (recipient principal) (amount uint) (response bool uint))

    ;; Get balance of an account
    (get-balance (account principal) (response uint uint))
  )
)

(define-constant ERR-NOT-AUTHORIZED u200)
(define-constant ERR-INSUFFICIENT-FUNDS u201)
(define-constant ERR-OFFER-NOT-FOUND u202)
(define-constant ERR-OFFER-EXPIRED u203)
(define-constant ERR-PAUSED u204)
(define-constant ERR-ZERO-ADDRESS u205)
(define-constant ERR-INVALID-AMOUNT u206)
(define-constant ERR-ESCROW-FAIL u207)
(define-constant ERR-ALREADY-CLAIMED u208)
(define-constant ERR-BATCH-LIMIT u209)

;; Contract state
(define-data-var admin principal tx-sender)
(define-data-var paused bool false)
(define-data-var token-contract principal 'SP000000000000000000002Q6VF78)
(define-data-var oracle principal 'SP000000000000000000002Q6VF78)

;; Offers map
(define-map offers
  {seller: principal, offer-id: uint}
  {energy: uint, price: uint, expiry: uint, buyer: (optional principal), claimed: bool}
)
(define-map offer-counters principal uint)
(define-map escrows {buyer: principal, offer-id: uint} uint)

;; Helpers
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

(define-private (ensure-not-paused)
  (asserts! (not (var-get paused)) (err ERR-PAUSED))
)

;; Admin transfer
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (asserts! (not (is-eq new-admin 'SP000000000000000000002Q6VF78)) (err ERR-ZERO-ADDRESS))
    (var-set admin new-admin)
    (ok true)
  )
)

;; Set token contract
(define-public (set-token-contract (new-token principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (var-set token-contract new-token)
    (ok true)
  )
)

;; Set oracle
(define-public (set-oracle (new-oracle principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (var-set oracle new-oracle)
    (ok true)
  )
)

;; Pause / unpause
(define-public (set-paused (pause bool))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (var-set paused pause)
    (ok pause)
  )
)

;; Create energy offer
(define-public (create-offer (energy uint) (price uint) (expiry uint))
  (begin
    (ensure-not-paused)
    (asserts! (> energy u0) (err ERR-INVALID-AMOUNT))
    (asserts! (> price u0) (err ERR-INVALID-AMOUNT))
    (asserts! (> expiry block-height) (err ERR-OFFER-EXPIRED))
    (let
      (
        (seller tx-sender)
        (offer-id (+ u1 (default-to u0 (map-get? offer-counters seller))))
      )
      (map-set offer-counters seller offer-id)
      (map-set offers {seller: seller, offer-id: offer-id}
        {energy: energy, price: price, expiry: expiry, buyer: none, claimed: false}
      )
      (print {event: "offer-created", seller: seller, offer-id: offer-id, energy: energy, price: price})
      (ok offer-id)
    )
  )
)

;; Buy offer
(define-public (buy-offer (seller principal) (offer-id uint))
  (begin
    (ensure-not-paused)
    (let
      (
        (offer-key {seller: seller, offer-id: offer-id})
        (offer (unwrap! (map-get? offers offer-key) (err ERR-OFFER-NOT-FOUND)))
      )
      (asserts! (is-none (get buyer offer)) (err ERR-ALREADY-CLAIMED))
      (asserts! (< block-height (get expiry offer)) (err ERR-OFFER-EXPIRED))
      (let
        (
          (total-price (* (get energy offer) (get price offer)))
          (buyer tx-sender)
        )
        (try! (as-contract (contract-call? (var-get token-contract) transfer tx-sender seller total-price)))
        (map-set offers offer-key (merge offer {buyer: (some buyer)}))
        (map-set escrows {buyer: buyer, offer-id: offer-id} total-price)
        (print {event: "offer-bought", buyer: buyer, seller: seller, offer-id: offer-id, price: total-price})
        (ok true)
      )
    )
  )
)

;; Confirm delivery
(define-public (confirm-delivery (seller principal) (offer-id uint))
  (begin
    (ensure-not-paused)
    (asserts! (or (is-eq tx-sender seller) (is-eq tx-sender (var-get oracle))) (err ERR-NOT-AUTHORIZED))
    (let
      (
        (offer-key {seller: seller, offer-id: offer-id})
        (offer (unwrap! (map-get? offers offer-key) (err ERR-OFFER-NOT-FOUND)))
      )
      (asserts! (not (get claimed offer)) (err ERR-ALREADY-CLAIMED))
      (let
        (
          (buyer (unwrap! (get buyer offer) (err ERR-OFFER-NOT-FOUND)))
          (escrow-key {buyer: buyer, offer-id: offer-id})
          (escrow-amount (default-to u0 (map-get? escrows escrow-key)))
        )
        (asserts! (> escrow-amount u0) (err ERR-ESCROW-FAIL))
        (try! (as-contract (contract-call? (var-get token-contract) transfer tx-sender seller escrow-amount)))
        (map-set offers offer-key (merge offer {claimed: true}))
        (map-delete escrows escrow-key)
        (print {event: "delivery-confirmed", seller: seller, buyer: buyer, offer-id: offer-id})
        (ok true)
      )
    )
  )
)

;; Resolve dispute
(define-public (resolve-dispute (seller principal) (offer-id uint) (refund-buyer bool))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (let
      (
        (offer-key {seller: seller, offer-id: offer-id})
        (offer (unwrap! (map-get? offers offer-key) (err ERR-OFFER-NOT-FOUND)))
      )
      (asserts! (not (get claimed offer)) (err ERR-ALREADY-CLAIMED))
      (let
        (
          (buyer (unwrap! (get buyer offer) (err ERR-OFFER-NOT-FOUND)))
          (escrow-key {buyer: buyer, offer-id: offer-id})
          (escrow-amount (default-to u0 (map-get? escrows escrow-key)))
        )
        (asserts! (> escrow-amount u0) (err ERR-ESCROW-FAIL))
        (if refund-buyer
          (try! (as-contract (contract-call? (var-get token-contract) transfer tx-sender buyer escrow-amount)))
          (try! (as-contract (contract-call? (var-get token-contract) transfer tx-sender seller escrow-amount)))
        )
        (map-set offers offer-key (merge offer {claimed: true}))
        (map-delete escrows escrow-key)
        (print {event: "dispute-resolved", seller: seller, buyer: buyer, offer-id: offer-id, refunded: refund-buyer})
        (ok true)
      )
    )
  )
)

;; Batch buy
(define-public (batch-buy (sellers (list 3 principal)) (offer-ids (list 3 uint)))
  (begin
    (ensure-not-paused)
    (asserts! (is-eq (len sellers) (len offer-ids)) (err ERR-INVALID-AMOUNT))
    (asserts! (<= (len sellers) u3) (err ERR-BATCH-LIMIT))
    (fold batch-buy-iter (zip sellers offer-ids) (ok u0))
  )
)

(define-private (batch-buy-iter (pair {seller: principal, id: uint}) (prev (response uint uint)))
  (match prev
    success
      (begin
        (try! (buy-offer (get seller pair) (get id pair)))
        (ok (+ success u1))
      )
    error error
  )
)

;; Read-onlys
(define-read-only (get-offer (seller principal) (offer-id uint))
  (map-get? offers {seller: seller, offer-id: offer-id})
)

(define-read-only (get-escrow (buyer principal) (offer-id uint))
  (ok (default-to u0 (map-get? escrows {buyer: buyer, offer-id: offer-id})))
)

(define-read-only (get-offer-counter (seller principal))
  (ok (default-to u0 (map-get? offer-counters seller)))
)

(define-read-only (get-admin)
  (ok (var-get admin))
)

(define-read-only (get-token-contract)
  (ok (var-get token-contract))
)

(define-read-only (get-oracle)
  (ok (var-get oracle))
)

(define-read-only (is-paused)
  (ok (var-get paused))
)
