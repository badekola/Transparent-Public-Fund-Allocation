;; procurement-verification.clar
;; Validates purchases follow procedures

;; Data Variables
(define-data-var admin principal tx-sender)
(define-map verifiers { address: principal } { active: bool })
(define-map verifications
  { expenditure-id: uint }
  { verifier: principal, verified: bool, timestamp: uint })
(define-map procurement-rules
  { department: principal }
  { threshold: uint, required-verifications: uint })
(define-map expenditure-details
  { id: uint }
  { department: principal, amount: uint, description: (string-ascii 100) })

;; Read-only functions
(define-read-only (is-verified (expenditure-id uint))
  (default-to false (get verified (map-get? verifications { expenditure-id: expenditure-id })))
)

(define-read-only (get-verification-details (expenditure-id uint))
  (map-get? verifications { expenditure-id: expenditure-id })
)

(define-read-only (is-authorized (address principal))
  (default-to false (get active (map-get? verifiers { address: address })))
)

(define-read-only (get-procurement-rules (department principal))
  (default-to { threshold: u10000, required-verifications: u1 }
    (map-get? procurement-rules { department: department }))
)

(define-read-only (is-admin (address principal))
  (is-eq address (var-get admin))
)

;; Public functions
(define-public (add-verifier (address principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u300))
    (ok (map-set verifiers { address: address } { active: true }))
  )
)

(define-public (remove-verifier (address principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u300))
    (ok (map-set verifiers { address: address } { active: false }))
  )
)

(define-public (set-procurement-rules (department principal) (threshold uint) (required-verifications uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u300))
    (asserts! (> required-verifications u0) (err u301))
    (ok (map-set procurement-rules
                { department: department }
                { threshold: threshold, required-verifications: required-verifications }))
  )
)

(define-public (register-expenditure (id uint) (department principal) (amount uint) (description (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u302))
    (ok (map-set expenditure-details
                { id: id }
                { department: department, amount: amount, description: description }))
  )
)

(define-public (verify-procurement (expenditure-id uint))
  (let ((expenditure (unwrap! (map-get? expenditure-details { id: expenditure-id }) (err u303))))
    (begin
      (asserts! (is-authorized tx-sender) (err u304))
      (asserts! (not (is-verified expenditure-id)) (err u305))

      ;; Check if the expenditure requires verification based on department rules
      (let ((department (get department expenditure))
            (amount (get amount expenditure))
            (rules (get-procurement-rules department)))
        (asserts! (>= amount (get threshold rules)) (err u306))

        (ok (map-set verifications
                    { expenditure-id: expenditure-id }
                    { verifier: tx-sender, verified: true, timestamp: block-height }))
      )
    )
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u307))
    (ok (var-set admin new-admin))
  )
)
