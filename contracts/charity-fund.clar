(define-constant err-not-found u100)
(define-constant err-inactive u101)
(define-constant err-expired u102)
(define-constant err-transfer-failed u103)
(define-constant err-not-admin u104)
(define-constant err-invalid-amount u105)
(define-constant err-invalid-campaign-id u106)
(define-constant err-goal-reached u107)
(define-constant err-goal-not-reached u108)
(define-constant err-campaign-not-ended u109)
(define-constant err-already-refunded u110)
(define-constant err-no-donation u111)

(define-data-var next-campaign-id uint u1)

(define-map campaigns
  { id: uint }
  {
    owner: principal,
    admin: principal,
    name: (string-utf8 100),
    goal: uint,
    total-donated: uint,
    end-height: uint,
    active: bool,
    goal-reached: bool,
    refund-enabled: bool
  }
)

(define-map donations
  { campaign-id: uint, donor: principal }
  uint
)

(define-map refunded
  { campaign-id: uint, donor: principal }
  bool
)

(define-public (create-campaign (admin principal) (name (string-utf8 100)) (goal uint) (end-height uint))
  (let (
        (campaign-id (var-get next-campaign-id))
        (campaign-data {
          owner: tx-sender,
          admin: admin,
          name: name,
          goal: goal,
          total-donated: u0,
          end-height: end-height,
          active: true,
          goal-reached: false,
          refund-enabled: false
        })
      )
    (begin
      (asserts! (> goal u0) (err err-invalid-amount))
      (asserts! (> end-height stacks-block-height) (err err-expired))
      (map-set campaigns { id: campaign-id } campaign-data)
      (var-set next-campaign-id (+ campaign-id u1))
      (ok campaign-id)
    )
  )
)

(define-public (donate (campaign-id uint) (amount uint))
  (begin
    (asserts! (> campaign-id u0) (err err-invalid-campaign-id))
    (asserts! (> amount u0) (err err-invalid-amount))
    (let ((campaign (map-get? campaigns { id: campaign-id })))
      (match campaign
        campaign-data
        (begin
          (asserts! (get active campaign-data) (err err-inactive))
          (asserts! (>= (get end-height campaign-data) stacks-block-height) (err err-expired))
          (let ((result (stx-transfer? amount tx-sender (as-contract tx-sender))))
            (unwrap! result (err err-transfer-failed)))
          (let ((current-total (get total-donated campaign-data))
                (new-total (+ current-total amount))
                (validated-campaign-id campaign-id)
                (validated-amount amount)
                (goal-reached (>= new-total (get goal campaign-data))))
            (map-set campaigns { id: validated-campaign-id }
              (merge campaign-data { 
                total-donated: new-total,
                goal-reached: goal-reached
              }))
            (let ((prev (default-to u0 (map-get? donations { campaign-id: validated-campaign-id, donor: tx-sender }))))
(map-set donations { campaign-id: validated-campaign-id, donor: tx-sender } (+ prev validated-amount))))
          (ok true))
        (err err-not-found))))
)

(define-public (withdraw (campaign-id uint) (amount uint))
  (begin
    (asserts! (> campaign-id u0) (err err-invalid-campaign-id))
    (asserts! (> amount u0) (err err-invalid-amount))
    (let ((campaign (map-get? campaigns { id: campaign-id })))
      (match campaign
        campaign-data
        (begin
          (asserts! (is-eq tx-sender (get admin campaign-data)) (err err-not-admin))
          (asserts! (get goal-reached campaign-data) (err err-goal-not-reached))
          (let ((validated-amount amount)
                (result (as-contract (stx-transfer? validated-amount tx-sender (get admin campaign-data)))))
            (unwrap! result (err err-transfer-failed)))
          (ok true))
        (err err-not-found))))
)

(define-public (enable-refund (campaign-id uint))
  (begin
    (asserts! (> campaign-id u0) (err err-invalid-campaign-id))
    (let ((campaign (map-get? campaigns { id: campaign-id })))
      (match campaign
        campaign-data
        (begin
          (asserts! (is-eq tx-sender (get admin campaign-data)) (err err-not-admin))
          (asserts! (< (get end-height campaign-data) stacks-block-height) (err err-campaign-not-ended))
          (asserts! (not (get goal-reached campaign-data)) (err err-goal-reached))
          (map-set campaigns { id: campaign-id }
            (merge campaign-data { 
              refund-enabled: true,
              active: false 
            }))
          (ok true))
        (err err-not-found))))
)

(define-public (auto-enable-refund (campaign-id uint))
  (begin
    (asserts! (> campaign-id u0) (err err-invalid-campaign-id))
    (let ((campaign (map-get? campaigns { id: campaign-id })))
      (match campaign
        campaign-data
        (begin
          (asserts! (< (get end-height campaign-data) stacks-block-height) (err err-campaign-not-ended))
          (asserts! (not (get goal-reached campaign-data)) (err err-goal-reached))
          (map-set campaigns { id: campaign-id }
            (merge campaign-data { 
              refund-enabled: true,
              active: false 
            }))
          (ok true))
        (err err-not-found))))
)

(define-public (claim-refund (campaign-id uint))
  (begin
    (asserts! (> campaign-id u0) (err err-invalid-campaign-id))
    (let ((campaign (map-get? campaigns { id: campaign-id })))
      (match campaign
        campaign-data
        (begin
          (asserts! (get refund-enabled campaign-data) (err err-goal-reached))
          (asserts! (not (default-to false (map-get? refunded { campaign-id: campaign-id, donor: tx-sender }))) (err err-already-refunded))
          (let ((donation-amount (default-to u0 (map-get? donations { campaign-id: campaign-id, donor: tx-sender }))))
            (asserts! (> donation-amount u0) (err err-no-donation))
(let ((result (as-contract (stx-transfer? donation-amount tx-sender tx-sender))))
              (unwrap! result (err err-transfer-failed)))
            (map-set refunded { campaign-id: campaign-id, donor: tx-sender } true)
            (ok donation-amount)))
        (err err-not-found))))
)

(define-public (finalize-campaign (campaign-id uint))
  (begin
    (asserts! (> campaign-id u0) (err err-invalid-campaign-id))
    (let ((campaign (map-get? campaigns { id: campaign-id })))
      (match campaign
        campaign-data
        (begin
          (asserts! (is-eq tx-sender (get admin campaign-data)) (err err-not-admin))
          (asserts! (< (get end-height campaign-data) stacks-block-height) (err err-campaign-not-ended))
          (if (get goal-reached campaign-data)
            (begin
              (map-set campaigns { id: campaign-id }
                (merge campaign-data { active: false }))
              (ok "goal-reached"))
            (begin
              (map-set campaigns { id: campaign-id }
                (merge campaign-data { 
                  refund-enabled: true,
                  active: false 
                }))
              (ok "refund-enabled"))))
        (err err-not-found))))
)

(define-read-only (get-campaign (campaign-id uint))
  (map-get? campaigns { id: campaign-id })
)

(define-read-only (get-donation (campaign-id uint) (donor principal))
  (default-to u0 (map-get? donations { campaign-id: campaign-id, donor: donor }))
)

(define-read-only (is-refunded (campaign-id uint) (donor principal))
  (default-to false (map-get? refunded { campaign-id: campaign-id, donor: donor }))
)

(define-read-only (get-current-block-height)
  stacks-block-height
)

(define-read-only (is-campaign-expired (campaign-id uint))
  (match (map-get? campaigns { id: campaign-id })
    campaign-data
    (< (get end-height campaign-data) stacks-block-height)
    true
  )
)

(define-read-only (can-claim-refund (campaign-id uint) (donor principal))
  (match (map-get? campaigns { id: campaign-id })
    campaign-data
    (and 
      (get refund-enabled campaign-data)
      (not (get goal-reached campaign-data))
      (not (is-refunded campaign-id donor))
      (> (get-donation campaign-id donor) u0))
    false
  )
)

(define-read-only (get-campaign-status (campaign-id uint))
  (match (map-get? campaigns { id: campaign-id })
    campaign-data
    (if (get active campaign-data)
      (if (< (get end-height campaign-data) stacks-block-height)
        "expired"
        "active")
      (if (get goal-reached campaign-data)
        "successful"
        "failed"))
    "not-found"
  )
)
