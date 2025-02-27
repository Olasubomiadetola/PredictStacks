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

