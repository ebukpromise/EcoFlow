;; Carbon Credit Token Contract

(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-INVALID-AMOUNT u101)
(define-constant ERR-INSUFFICIENT-BALANCE u102)
(define-constant ERR-ZERO-ADDRESS u103)
(define-constant ERR-MAX-SUPPLY-REACHED u104)
(define-constant ERR-CONTRACT-PAUSED u105)

(define-constant MAX-SUPPLY u1000000)

(define-data-var admin principal tx-sender)
(define-data-var oracle principal 'SP000000000000000000002Q6VF78) ;; placeholder
(define-data-var paused bool false)
(define-data-var total-supply uint u0)
(define-map balances principal uint)

;; --------------------------------
;; Utility functions
;; --------------------------------
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

(define-private (ensure-not-paused)
  (asserts! (not (var-get paused)) (err ERR-CONTRACT-PAUSED))
)

;; --------------------------------
;; Internal mint function
;; --------------------------------
(define-private (mint-internal (recipient principal) (amount uint))
  (begin
    (asserts! (not (is-eq recipient 'SP000000000000000000002Q6VF78)) (err ERR-ZERO-ADDRESS))
    (asserts! (> amount u0) (err ERR-INVALID-AMOUNT))
    (let (
          (new-supply (+ (var-get total-supply) amount))
         )
      (asserts! (<= new-supply MAX-SUPPLY) (err ERR-MAX-SUPPLY-REACHED))
      (map-set balances recipient (+ amount (default-to u0 (map-get? balances recipient))))
      (var-set total-supply new-supply)
      (print {event: "mint", recipient: recipient, amount: amount})
      (ok true)
    )
  )
)

;; --------------------------------
;; Public functions
;; --------------------------------

;; Admin-only mint
(define-public (mint (recipient principal) (amount uint))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (try! (mint-internal recipient amount))
    (ok true)
  )
)

;; Oracle-triggered mint
(define-public (oracle-mint (producer principal) (emissions-reduced uint))
  (begin
    (ensure-not-paused)
    (asserts! (is-eq tx-sender (var-get oracle)) (err ERR-NOT-AUTHORIZED))
    (try! (mint-internal producer emissions-reduced))
    (ok true)
  )
)

;; Transfer tokens
(define-public (transfer (recipient principal) (amount uint))
  (begin
    (ensure-not-paused)
    (asserts! (not (is-eq recipient tx-sender)) (err ERR-ZERO-ADDRESS))
    (asserts! (> amount u0) (err ERR-INVALID-AMOUNT))
    (let ((sender-balance (default-to u0 (map-get? balances tx-sender))))
      (asserts! (>= sender-balance amount) (err ERR-INSUFFICIENT-BALANCE))
      (map-set balances tx-sender (- sender-balance amount))
      (map-set balances recipient (+ amount (default-to u0 (map-get? balances recipient))))
      (print {event: "transfer", from: tx-sender, to: recipient, amount: amount})
      (ok true)
    )
  )
)

;; Batch transfer without recursion
(define-public (batch-transfer (recipients (list 200 principal)) (amounts (list 200 uint)))
  (begin
    (ensure-not-paused)
    (asserts! (is-eq (len recipients) (len amounts)) (err u999))
    (map
      (lambda (pair)
        (let ((recipient (get recipient pair))
              (amount (get amount pair)))
          (try! (transfer recipient amount))
        )
      )
      (map
        (lambda (idx)
          {recipient: (element-at recipients idx), amount: (element-at amounts idx)}
        )
        (range u0 (len recipients))
      )
    )
    (ok true)
  )
)

;; Admin-only batch transfer
(define-public (batch-transfer-at (recipients (list 200 principal)) (amounts (list 200 uint)))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (try! (batch-transfer recipients amounts))
    (ok true)
  )
)

;; --------------------------------
;; Admin controls
;; --------------------------------
(define-public (set-oracle (new-oracle principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (var-set oracle new-oracle)
    (ok true)
  )
)

(define-public (pause)
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (var-set paused true)
    (ok true)
  )
)

(define-public (unpause)
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (var-set paused false)
    (ok true)
  )
)

;; --------------------------------
;; Read-only functions
;; --------------------------------
(define-read-only (get-balance (owner principal))
  (ok (default-to u0 (map-get? balances owner)))
)

(define-read-only (get-total-supply)
  (ok (var-get total-supply))
)

(define-read-only (get-admin)
  (ok (var-get admin))
)

(define-read-only (get-oracle)
  (ok (var-get oracle))
)

(define-read-only (is-paused)
  (ok (var-get paused))
)
