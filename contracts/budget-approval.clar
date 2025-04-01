;; budget-approval.clar
;; Records authorized spending by department

;; Data Variables
(define-data-var admin principal tx-sender)
(define-map budgets
  { department: principal, fiscal-year: uint }
  { amount: uint, spent: uint })

;; Read-only functions
(define-read-only (get-budget (department principal) (fiscal-year uint))
  (default-to { amount: u0, spent: u0 }
    (map-get? budgets { department: department, fiscal-year: fiscal-year }))
)

(define-read-only (get-remaining-budget (department principal) (fiscal-year uint))
  (let ((budget (get-budget department fiscal-year)))
    (- (get amount budget) (get spent budget))
  )
)

(define-read-only (is-admin (address principal))
  (is-eq address (var-get admin))
)

;; Public functions
(define-public (approve-budget (department principal) (amount uint) (fiscal-year uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (asserts! (> amount u0) (err u101))
    (ok (map-set budgets
                { department: department, fiscal-year: fiscal-year }
                { amount: amount, spent: u0 }))
  )
)

(define-public (update-spent (department principal) (fiscal-year uint) (new-spent uint))
  (let ((budget (get-budget department fiscal-year)))
    (begin
      (asserts! (<= new-spent (get amount budget)) (err u103))
      (ok (map-set budgets
                  { department: department, fiscal-year: fiscal-year }
                  { amount: (get amount budget), spent: new-spent }))
    )
  )
)

;; Adjust spent amount - only supports increasing the spent amount
(define-public (increase-spent (department principal) (fiscal-year uint) (amount-to-add uint))
  (let ((budget (get-budget department fiscal-year))
        (current-spent (get spent budget))
        (new-spent (+ current-spent amount-to-add)))
    (begin
      (asserts! (<= new-spent (get amount budget)) (err u103))
      (ok (map-set budgets
                  { department: department, fiscal-year: fiscal-year }
                  { amount: (get amount budget), spent: new-spent }))
    )
  )
)

;; Decrease spent amount
(define-public (decrease-spent (department principal) (fiscal-year uint) (amount-to-subtract uint))
  (let ((budget (get-budget department fiscal-year))
        (current-spent (get spent budget)))
    (begin
      (asserts! (>= current-spent amount-to-subtract) (err u104))
      (ok (map-set budgets
                  { department: department, fiscal-year: fiscal-year }
                  { amount: (get amount budget), spent: (- current-spent amount-to-subtract) }))
    )
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u102))
    (ok (var-set admin new-admin))
  )
)
