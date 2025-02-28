;; CodeVault Contract

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-BRANCH (err u103))
(define-constant ERR-INVALID-ACCESS-LEVEL (err u104))
(define-constant ERR-INVALID-INPUT (err u105))

;; Access Level Constants
(define-constant ACCESS-LEVEL-READ u1)
(define-constant ACCESS-LEVEL-WRITE u2)
(define-constant ACCESS-LEVEL-ADMIN u3)

;; [Previous data maps remain unchanged...]

;; New read-only function
(define-read-only (get-commit (project-id uint) (commit-id uint))
    (map-get? project-commits { project-id: project-id, commit-id: commit-id })
)

;; Enhanced project creation with input validation
(define-public (create-project (name (string-ascii 64)) (description (string-ascii 256)) (is-public bool))
    (let ((project-id (var-get next-project-id)))
        (asserts! (> (len name) u0) ERR-INVALID-INPUT)
        (asserts! (> (len description) u0) ERR-INVALID-INPUT)
        (try! (create-project-helper project-id name description is-public))
        (try! (add-project-member project-id tx-sender ACCESS-LEVEL-ADMIN))
        (try! (create-branch project-id "main" "main"))
        (ok project-id)
    )
)

;; Enhanced member management
(define-public (add-project-member (project-id uint) (member principal) (access-level uint))
    (let ((project (map-get? projects { project-id: project-id })))
        (asserts! (is-some project) ERR-NOT-FOUND)
        (asserts! (is-eq (some tx-sender) (get owner project)) ERR-NOT-AUTHORIZED)
        (asserts! (and (>= access-level ACCESS-LEVEL-READ) (<= access-level ACCESS-LEVEL-ADMIN)) ERR-INVALID-ACCESS-LEVEL)
        (map-set project-members
            { project-id: project-id, member: member }
            { access-level: access-level }
        )
        (ok true)
    )
)

;; New function to remove project members
(define-public (remove-project-member (project-id uint) (member principal))
    (let ((project (map-get? projects { project-id: project-id })))
        (asserts! (is-some project) ERR-NOT-FOUND)
        (asserts! (is-eq (some tx-sender) (get owner project)) ERR-NOT-AUTHORIZED)
        (asserts! (not (is-eq member tx-sender)) ERR-NOT-AUTHORIZED)
        (map-delete project-members { project-id: project-id, member: member })
        (ok true)
    )
)

;; [Rest of the contract remains unchanged...]
