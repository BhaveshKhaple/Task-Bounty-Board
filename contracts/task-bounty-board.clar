;; Task Bounty Board - Minimal Version
;; Two core functions: post-bounty and claim-bounty

(define-constant err-invalid-amount (err u100))
(define-constant err-task-exists (err u101))
(define-constant err-task-not-found (err u102))
(define-constant err-not-creator (err u103))
(define-constant err-already-claimed (err u104))

;; Data map to store tasks
;; task-id => { creator, amount, description, claimed }
(define-map tasks uint
  { creator: principal,
    amount: uint,
    description: (string-ascii 100),
    claimed: bool })

;; Track the next task ID
(define-data-var next-task-id uint u1)

;; Function 1: Post a bounty
(define-public (post-bounty (description (string-ascii 100)) (amount uint))
  (begin
    (asserts! (> amount u0) err-invalid-amount)

    (let ((task-id (var-get next-task-id)))
      ;; Check if task already exists (should not)
      (asserts! (is-none (map-get? tasks task-id)) err-task-exists)

      ;; Transfer bounty STX to contract
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

      ;; Save task details
      (map-set tasks task-id
        { creator: tx-sender,
          amount: amount,
          description: description,
          claimed: false })

      ;; Increment next-task-id
      (var-set next-task-id (+ task-id u1))

      (ok task-id)
    )
  )
)

;; Function 2: Claim a bounty
(define-public (claim-bounty (task-id uint) (claimer principal))
  (begin
    (match (map-get? tasks task-id)
      task
      (begin
        (asserts! (is-eq (get claimed task) false) err-already-claimed)

        ;; Mark as claimed
        (map-set tasks task-id
          { creator: (get creator task),
            amount: (get amount task),
            description: (get description task),
            claimed: true })

        ;; Transfer STX to claimer
        (try! (stx-transfer? (get amount task) (as-contract tx-sender) claimer))

        (ok true)
      )
      err-task-not-found
    )
  )
)
