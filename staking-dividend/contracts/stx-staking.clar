;; Smart contract on STX dividend-distribution

;; Constants
(define-constant CONTRACT-ADMIN tx-sender)
(define-constant ERR-ADMIN-ONLY (err u100))
(define-constant ERR-NO-PAYOUTS (err u101))
(define-constant ERR-TRANSFER-FAILED (err u102))
(define-constant ERR-INVALID-SUM (err u103))
(define-constant ERR-UPDATE-HOLDINGS-FAILED (err u104))
(define-constant ERR-PAYOUT-PERIOD-NOT-REACHED (err u105))
(define-constant ERR-NO-UNCLAIMED-PAYOUTS (err u106))
(define-constant MINIMUM-PAYOUT-BLOCK-INTERVAL u10000)

;; Data variables
(define-data-var cumulative-dividend-pool uint u0)
(define-data-var dividend-rate-per-token uint u0)
(define-data-var previous-dividend-block uint u0)
(define-data-var total-staked-tokens uint u0)
(define-data-var total-claimed-dividends uint u0)

;; Data maps
(define-map user-claimed-dividends principal uint)
(define-map user-staked-balance principal uint)

;; Read-only functions
(define-read-only (get-dividend-rate-per-token)
  (var-get dividend-rate-per-token)
)

(define-read-only (get-claimable-dividends (account principal))
  (let (
    (staked-balance (stx-get-balance account))
    (previously-claimed (default-to u0 (map-get? user-claimed-dividends account)))
    (total-dividend-entitlement (* staked-balance (var-get dividend-rate-per-token)))
  )
    (if (> total-dividend-entitlement previously-claimed)
        (- total-dividend-entitlement previously-claimed)
        u0)
  )
)

(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)

;; Private functions
(define-private (update-dividend-rate (new-dividend-amount uint))
  (let (
    (staked-token-supply (var-get total-staked-tokens))
    (new-dividend-pool (+ (var-get cumulative-dividend-pool) new-dividend-amount))
  )
    (if (> staked-token-supply u0)
        (var-set dividend-rate-per-token (/ new-dividend-pool staked-token-supply))
        (var-set dividend-rate-per-token u0))
    (var-set cumulative-dividend-pool new-dividend-pool)
  )
)

;; Public functions
(define-public (add-dividends (dividend-amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-ADMIN) ERR-ADMIN-ONLY)
    (asserts! (> dividend-amount u0) ERR-INVALID-SUM)
    (try! (stx-transfer? dividend-amount tx-sender (as-contract tx-sender)))
    (update-dividend-rate dividend-amount)
    (var-set previous-dividend-block block-height)
    (ok true)
  )
)

(define-public (update-staked-balance)
  (let (
    (current-staked-balance (stx-get-balance tx-sender))
    (previous-staked-balance (default-to u0 (map-get? user-staked-balance tx-sender)))
  )
    (map-set user-staked-balance tx-sender current-staked-balance)
    (var-set total-staked-tokens (+ (var-get total-staked-tokens) (- current-staked-balance previous-staked-balance)))
    (ok current-staked-balance)
  )
)

(define-public (claim-dividends)
  (let (
    (staked-balance (unwrap! (update-staked-balance) ERR-UPDATE-HOLDINGS-FAILED))
    (claimable-amount (get-claimable-dividends tx-sender))
  )
    (asserts! (> claimable-amount u0) ERR-NO-PAYOUTS)
    (map-set user-claimed-dividends tx-sender 
             (+ (default-to u0 (map-get? user-claimed-dividends tx-sender)) claimable-amount))
    (var-set total-claimed-dividends (+ (var-get total-claimed-dividends) claimable-amount))
    (as-contract (stx-transfer? claimable-amount tx-sender tx-sender))
  )
)

(define-public (update-total-staked)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-ADMIN) ERR-ADMIN-ONLY)
    (var-set total-staked-tokens (stx-get-balance (as-contract tx-sender)))
    (ok (var-get total-staked-tokens))
  )
)

(define-public (withdraw-unclaimed-dividends)
  (let (
    (current-block block-height)
    (last-dividend-block (var-get previous-dividend-block))
    (unclaimed-amount (- (var-get cumulative-dividend-pool) (var-get total-claimed-dividends)))
  )
    (asserts! (is-eq tx-sender CONTRACT-ADMIN) ERR-ADMIN-ONLY)
    (asserts! (> (- current-block last-dividend-block) MINIMUM-PAYOUT-BLOCK-INTERVAL) ERR-PAYOUT-PERIOD-NOT-REACHED)
    (asserts! (> unclaimed-amount u0) ERR-NO-UNCLAIMED-PAYOUTS)
    (var-set cumulative-dividend-pool (- (var-get cumulative-dividend-pool) unclaimed-amount))
    (as-contract (stx-transfer? unclaimed-amount tx-sender CONTRACT-ADMIN))
  )
)

;; Initialize contract
(begin
  (var-set cumulative-dividend-pool u0)
  (var-set dividend-rate-per-token u0)
  (var-set previous-dividend-block block-height)
  (var-set total-staked-tokens u0)
  (var-set total-claimed-dividends u0)
)