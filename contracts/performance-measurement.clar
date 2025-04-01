;; performance-measurement.clar
;; Tracks outcomes of funded projects

;; Data Variables
(define-data-var admin principal tx-sender)
(define-data-var project-counter uint u0)
(define-map projects
  { id: uint }
  { name: (string-ascii 100),
    department: principal,
    budget: uint,
    start-block: uint,
    end-block: uint })

(define-map project-managers
  { project-id: uint, manager: principal }
  { active: bool })

(define-map performance-metrics
  { project-id: uint, metric-name: (string-ascii 50) }
  { value: uint, recorded-by: principal, timestamp: uint })

(define-map project-milestones
  { project-id: uint, milestone-id: uint }
  { description: (string-ascii 100),
    target-block: uint,
    completed: bool,
    completion-block: uint })

;; Read-only functions
(define-read-only (get-project (project-id uint))
  (map-get? projects { id: project-id })
)

(define-read-only (get-project-count)
  (var-get project-counter)
)

(define-read-only (is-project-manager (address principal) (project-id uint))
  (default-to false (get active (map-get? project-managers { project-id: project-id, manager: address })))
)

(define-read-only (get-performance-metric (project-id uint) (metric-name (string-ascii 50)))
  (map-get? performance-metrics { project-id: project-id, metric-name: metric-name })
)

(define-read-only (get-project-milestone (project-id uint) (milestone-id uint))
  (map-get? project-milestones { project-id: project-id, milestone-id: milestone-id })
)

;; Public functions
(define-public (register-project (name (string-ascii 100)) (department principal) (budget uint) (duration uint))
  (let ((project-id (var-get project-counter)))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u400))
      (asserts! (> budget u0) (err u401))
      (asserts! (> duration u0) (err u402))

      (var-set project-counter (+ project-id u1))
      (ok (map-set projects
                  { id: project-id }
                  { name: name,
                    department: department,
                    budget: budget,
                    start-block: block-height,
                    end-block: (+ block-height duration) }))
    )
  )
)

(define-public (add-project-manager (project-id uint) (manager principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u400))
    (asserts! (is-some (get-project project-id)) (err u403))
    (ok (map-set project-managers
                { project-id: project-id, manager: manager }
                { active: true }))
  )
)

(define-public (remove-project-manager (project-id uint) (manager principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u400))
    (asserts! (is-some (get-project project-id)) (err u403))
    (ok (map-set project-managers
                { project-id: project-id, manager: manager }
                { active: false }))
  )
)

(define-public (record-performance-metric (project-id uint) (metric-name (string-ascii 50)) (value uint))
  (begin
    (asserts! (is-project-manager tx-sender project-id) (err u404))
    (asserts! (is-some (get-project project-id)) (err u403))
    (ok (map-set performance-metrics
                { project-id: project-id, metric-name: metric-name }
                { value: value, recorded-by: tx-sender, timestamp: block-height }))
  )
)

(define-public (add-project-milestone (project-id uint) (milestone-id uint) (description (string-ascii 100)) (target-block uint))
  (begin
    (asserts! (is-project-manager tx-sender project-id) (err u404))
    (asserts! (is-some (get-project project-id)) (err u403))
    (ok (map-set project-milestones
                { project-id: project-id, milestone-id: milestone-id }
                { description: description,
                  target-block: target-block,
                  completed: false,
                  completion-block: u0 }))
  )
)

(define-public (complete-project-milestone (project-id uint) (milestone-id uint))
  (let ((milestone (unwrap! (get-project-milestone project-id milestone-id) (err u405))))
    (begin
      (asserts! (is-project-manager tx-sender project-id) (err u404))
      (asserts! (not (get completed milestone)) (err u406))
      (ok (map-set project-milestones
                  { project-id: project-id, milestone-id: milestone-id }
                  (merge milestone { completed: true, completion-block: block-height })))
    )
  )
)
