;; CodeVault Contract

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-BRANCH (err u103))

;; Data Maps
(define-map projects 
    { project-id: uint }
    {
        name: (string-ascii 64),
        owner: principal,
        description: (string-ascii 256), 
        is-public: bool,
        created-at: uint,
        default-branch: (string-ascii 32)
    }
)

(define-map project-members
    { project-id: uint, member: principal }
    { access-level: uint }  ;; 1: read, 2: write, 3: admin
)

(define-map project-commits
    { project-id: uint, commit-id: uint }
    {
        hash: (string-ascii 64),
        message: (string-ascii 256),
        author: principal,
        timestamp: uint,
        branch: (string-ascii 32)
    }
)

(define-map project-branches
    { project-id: uint, branch-name: (string-ascii 32) }
    {
        base-branch: (string-ascii 32),
        created-at: uint,
        last-commit: uint
    }
)

;; Data Variables
(define-data-var next-project-id uint u1)
(define-data-var next-commit-id uint u1)

;; Read-only functions 
(define-read-only (get-project (project-id uint))
    (map-get? projects { project-id: project-id })
)

(define-read-only (get-member-access (project-id uint) (member principal))
    (default-to u0 
        (get access-level 
            (map-get? project-members { project-id: project-id, member: member })
        )
    )
)

(define-read-only (get-branch (project-id uint) (branch-name (string-ascii 32)))
    (map-get? project-branches { project-id: project-id, branch-name: branch-name })
)

;; Public functions
(define-public (create-project (name (string-ascii 64)) (description (string-ascii 256)) (is-public bool))
    (let ((project-id (var-get next-project-id)))
        (try! (create-project-helper project-id name description is-public))
        ;; Add creator as admin
        (try! (add-project-member project-id tx-sender u3))
        ;; Create main branch
        (try! (create-branch project-id "main" "main"))
        (ok project-id)
    )
)

(define-private (create-project-helper (project-id uint) (name (string-ascii 64)) (description (string-ascii 256)) (is-public bool))
    (begin
        (map-set projects 
            { project-id: project-id }
            {
                name: name,
                owner: tx-sender,
                description: description,
                is-public: is-public,
                created-at: block-height,
                default-branch: "main"
            }
        )
        (var-set next-project-id (+ project-id u1))
        (ok true)
    )
)

(define-public (create-branch (project-id uint) (branch-name (string-ascii 32)) (base-branch (string-ascii 32)))
    (let (
        (access-level (get-member-access project-id tx-sender))
        (base (get-branch project-id base-branch))
    )
        (asserts! (>= access-level u2) ERR-NOT-AUTHORIZED)
        (asserts! (or (is-eq base-branch "main") (is-some base)) ERR-INVALID-BRANCH)
        (map-set project-branches
            { project-id: project-id, branch-name: branch-name }
            {
                base-branch: base-branch,
                created-at: block-height,
                last-commit: u0
            }
        )
        (ok true)
    )
)

(define-public (add-project-member (project-id uint) (member principal) (access-level uint))
    (let ((project (map-get? projects { project-id: project-id })))
        (asserts! (is-eq (some tx-sender) (get owner project)) ERR-NOT-AUTHORIZED)
        (asserts! (<= access-level u3) ERR-NOT-AUTHORIZED)
        (map-set project-members
            { project-id: project-id, member: member }
            { access-level: access-level }
        )
        (ok true)
    )
)

(define-public (record-commit (project-id uint) (hash (string-ascii 64)) (message (string-ascii 256)) (branch (string-ascii 32)))
    (let (
        (commit-id (var-get next-commit-id))
        (access-level (get-member-access project-id tx-sender))
        (branch-info (get-branch project-id branch))
    )
        (asserts! (>= access-level u2) ERR-NOT-AUTHORIZED)
        (asserts! (is-some branch-info) ERR-INVALID-BRANCH)
        (map-set project-commits
            { project-id: project-id, commit-id: commit-id }
            {
                hash: hash,
                message: message,
                author: tx-sender,
                timestamp: block-height,
                branch: branch
            }
        )
        (map-set project-branches
            { project-id: project-id, branch-name: branch }
            (merge (unwrap-panic branch-info) { last-commit: commit-id })
        )
        (var-set next-commit-id (+ commit-id u1))
        (ok commit-id)
    )
)

(define-public (update-project-visibility (project-id uint) (is-public bool))
    (let ((project (map-get? projects { project-id: project-id })))
        (asserts! (is-eq (some tx-sender) (get owner project)) ERR-NOT-AUTHORIZED)
        (map-set projects
            { project-id: project-id }
            (merge (unwrap-panic project) { is-public: is-public })
        )
        (ok true)
    )
)
