;; CodeVault Contract
;; Secure repository management system with enhanced member access control

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

;; Read-only function to get member access level
(define-read-only (get-member-access (project-id uint) (member principal))
    (default-to u0 (get access-level (map-get? project-members 
        { project-id: project-id, member: member })))
)

;; Helper function to check admin privileges
(define-private (is-project-admin (project-id uint) (user principal))
    (is-eq (get-member-access project-id user) ACCESS-LEVEL-ADMIN)
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

;; Enhanced member management with proper validation
(define-public (add-project-member (project-id uint) (member principal) (access-level uint))
    (let (
        (project (unwrap! (map-get? projects { project-id: project-id }) ERR-NOT-FOUND))
        (current-access (get-member-access project-id member))
    )
        (asserts! (is-project-admin project-id tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (and (>= access-level ACCESS-LEVEL-READ) (<= access-level ACCESS-LEVEL-ADMIN)) ERR-INVALID-ACCESS-LEVEL)
        (asserts! (is-eq current-access u0) ERR-ALREADY-EXISTS)
        (map-set project-members
            { project-id: project-id, member: member }
            { access-level: access-level }
        )
        (ok true)
    )
)

;; Enhanced member removal with proper validation
(define-public (remove-project-member (project-id uint) (member principal))
    (let (
        (project (unwrap! (map-get? projects { project-id: project-id }) ERR-NOT-FOUND))
        (member-access (get-member-access project-id member))
    )
        (asserts! (is-project-admin project-id tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (not (is-eq member tx-sender)) ERR-NOT-AUTHORIZED)
        (asserts! (> member-access u0) ERR-NOT-FOUND)
        (map-delete project-members { project-id: project-id, member: member })
        (ok true)
    )
)

;; [Rest of the contract remains unchanged...]
