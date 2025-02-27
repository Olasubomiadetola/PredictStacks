;; stx-prediction-market
;; stacks Prediction Market Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-bet (err u101))
(define-constant err-event-closed (err u102))
(define-constant err-event-not-resolved (err u103))
(define-constant err-invalid-option (err u104))
(define-constant err-invalid-amount (err u105))
(define-constant err-overflow (err u106))
(define-constant err-insufficient-balance (err u107))
(define-constant err-event-not-cancelable (err u108))
(define-constant err-no-bets-placed (err u109))

(define-constant fee-percentage u5)
(define-constant fee-denominator u1000)


;; Data Maps
(define-map events 
  { event-id: uint }
  {
    description: (string-ascii 256),
    options: (list 10 (string-ascii 64)),
    total-bets: uint,
    is-resolved: bool,
    winning-option: (optional uint),
    resolution-time: uint,
    creator: principal,
    is-canceled: bool
  }
)


(define-map bets
  { event-id: uint, better: principal }
  {
    amount: uint,
    option: uint
  }
)

(define-map event-odds
  { event-id: uint, option: uint }
  { odds: uint }
)

;; Initialize next event ID
(define-data-var next-event-id uint u0)

;; Public Functions
(define-public (create-event (description (string-ascii 256)) (options (list 10 (string-ascii 64))) (resolution-time uint))
  (let ((event-id (var-get next-event-id)))
    (asserts! (> (len options) u0) err-invalid-bet)
    (asserts! (<= (len options) u10) err-invalid-bet)
    (asserts! (> resolution-time (unwrap-panic (get-block-info? time (- block-height u1)))) err-invalid-bet)
    (map-set events { event-id: event-id }
      {
        description: description,
        options: options,
        total-bets: u0,
        is-resolved: false,
        winning-option: none,
        resolution-time: resolution-time,
        creator: tx-sender,
        is-canceled: false
      }
    )
    (var-set next-event-id (+ event-id u1))
    (ok event-id)
  )
)


;; Place a bet on an event
(define-public (place-bet (event-id uint) (option uint) (amount uint))
  (let (
    (event (unwrap! (map-get? events { event-id: event-id }) err-invalid-bet))
    (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
  )
    (asserts! (< current-time (get resolution-time event)) err-event-closed)
    (asserts! (is-none (get winning-option event)) err-event-closed)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (< option (len (get options event))) err-invalid-option)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set bets { event-id: event-id, better: tx-sender } { amount: amount, option: option })
    (map-set events { event-id: event-id }
      (merge event { total-bets: (try! (add-safe (get total-bets event) amount)) })
    )
    (ok true)
  )
)

;; Resolve an event
(define-public (resolve-event (event-id uint) (winning-option uint))
  (let ((event (unwrap! (map-get? events { event-id: event-id }) err-invalid-bet)))
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (asserts! (is-none (get winning-option event)) err-event-closed)
    (asserts! (>= (unwrap-panic (get-block-info? time (- block-height u1))) (get resolution-time event)) err-event-not-resolved)
    (asserts! (< winning-option (len (get options event))) err-invalid-option)
    (map-set events { event-id: event-id }
      (merge event { 
        is-resolved: true,
        winning-option: (some winning-option)
      })
    )
    (ok true)
  )
)

;; Claim winnings
(define-public (claim-winnings (event-id uint))
  (let (
    (event (unwrap! (map-get? events { event-id: event-id }) err-invalid-bet))
    (bet (unwrap! (map-get? bets { event-id: event-id, better: tx-sender }) err-invalid-bet))
    (winning-option (unwrap! (get winning-option event) err-event-not-resolved))
  )
    (asserts! (is-eq (get option bet) winning-option) err-invalid-bet)
    (let (
      (total-bets (get total-bets event))
      (option-bets (get-total-bets-for-option event-id winning-option))
    )
      (asserts! (> option-bets u0) err-invalid-bet)
      (let (
        (winning-amount (/ (* (get amount bet) total-bets) option-bets))
      )
        (try! (as-contract (stx-transfer? winning-amount tx-sender tx-sender)))
        (map-delete bets { event-id: event-id, better: tx-sender })
        (ok winning-amount)
      )
    )
  )
)

(define-private (get-bet-amount-for-option (bet { amount: uint, option: uint }) (target-option uint))
  (if (is-eq (get option bet) target-option)
    (get amount bet)
    u0
  )
)


;; Get total bets for a specific option
(define-private (get-total-bets-for-option (event-id uint) (option uint))
  (let ((bets-for-event (map-get? bets { event-id: event-id, better: tx-sender })))
    (match bets-for-event
      bet (if (is-eq (get option bet) option)
              (get amount bet)
              u0)
      u0)
  )
)

;; Safe addition to prevent overflow
(define-private (add-safe (a uint) (b uint))
  (let ((sum (+ a b)))
    (asserts! (>= sum a) err-overflow)
    (ok sum)
  )
)

;; Read-only functions

;; Get event details
(define-read-only (get-event (event-id uint))
  (map-get? events { event-id: event-id })
)

;; Get bet details
(define-read-only (get-bet (event-id uint) (better principal))
  (map-get? bets { event-id: event-id, better: better })
)
