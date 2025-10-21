;; title: biodiversity-index
;; version: 1.0.0
;; summary: On-chain Biodiversity Index - Tokenized registry of species sightings
;; description: A decentralized platform for communities to contribute and verify species sightings

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-verified (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-data (err u104))

;; data vars
(define-data-var sighting-nonce uint u0)
(define-data-var total-species-count uint u0)
(define-data-var verification-reward uint u10) ;; reward in micro-STX for verification

;; data maps
;; Store sighting details
(define-map sightings
  uint
  {
    species-name: (string-ascii 100),
    scientific-name: (string-ascii 100),
    location: (string-ascii 200),
    latitude: int,
    longitude: int,
    observer: principal,
    timestamp: uint,
    verified: bool,
    verifier: (optional principal),
    notes: (string-utf8 500)
  }
)

;; Track unique species by name
(define-map species-registry
  (string-ascii 100)
  {
    first-sighting-id: uint,
    total-sightings: uint,
    last-seen: uint
  }
)

;; Track contributor stats
(define-map contributor-stats
  principal
  {
    total-sightings: uint,
    verified-sightings: uint,
    reputation-score: uint
  }
)

;; Track verifier stats
(define-map verifier-stats
  principal
  {
    total-verifications: uint,
    verifier-since: uint
  }
)

;; public functions

;; Submit a new species sighting
(define-public (submit-sighting
  (species-name (string-ascii 100))
  (scientific-name (string-ascii 100))
  (location (string-ascii 200))
  (latitude int)
  (longitude int)
  (notes (string-utf8 500)))
  (let
    (
      (sighting-id (var-get sighting-nonce))
      (contributor tx-sender)
    )
    ;; Validate input
    (asserts! (> (len species-name) u0) err-invalid-data)
    (asserts! (> (len location) u0) err-invalid-data)

    ;; Store the sighting
    (map-set sightings sighting-id
      {
        species-name: species-name,
        scientific-name: scientific-name,
        location: location,
        latitude: latitude,
        longitude: longitude,
        observer: contributor,
        timestamp: block-height,
        verified: false,
        verifier: none,
        notes: notes
      }
    )

    ;; Update species registry
    (match (map-get? species-registry species-name)
      existing-species (map-set species-registry species-name
        {
          first-sighting-id: (get first-sighting-id existing-species),
          total-sightings: (+ (get total-sightings existing-species) u1),
          last-seen: block-height
        }
      )
      ;; First sighting of this species
      (begin
        (map-set species-registry species-name
          {
            first-sighting-id: sighting-id,
            total-sightings: u1,
            last-seen: block-height
          }
        )
        (var-set total-species-count (+ (var-get total-species-count) u1))
      )
    )

    ;; Update contributor stats
    (match (map-get? contributor-stats contributor)
      existing-stats (map-set contributor-stats contributor
        {
          total-sightings: (+ (get total-sightings existing-stats) u1),
          verified-sightings: (get verified-sightings existing-stats),
          reputation-score: (get reputation-score existing-stats)
        }
      )
      ;; First contribution
      (map-set contributor-stats contributor
        {
          total-sightings: u1,
          verified-sightings: u0,
          reputation-score: u0
        }
      )
    )

    ;; Increment sighting nonce
    (var-set sighting-nonce (+ sighting-id u1))

    (ok sighting-id)
  )
)

;; Verify a sighting (community verification)
(define-public (verify-sighting (sighting-id uint))
  (let
    (
      (sighting (unwrap! (map-get? sightings sighting-id) err-not-found))
      (verifier tx-sender)
      (observer (get observer sighting))
    )
    ;; Check if already verified
    (asserts! (not (get verified sighting)) err-already-verified)

    ;; Verifier cannot be the observer
    (asserts! (not (is-eq verifier observer)) err-unauthorized)

    ;; Update sighting with verification
    (map-set sightings sighting-id
      (merge sighting {
        verified: true,
        verifier: (some verifier)
      })
    )

    ;; Update observer's stats (increase reputation)
    (match (map-get? contributor-stats observer)
      stats (begin
        (map-set contributor-stats observer
          {
            total-sightings: (get total-sightings stats),
            verified-sightings: (+ (get verified-sightings stats) u1),
            reputation-score: (+ (get reputation-score stats) u10)
          }
        )
        true
      )
      false
    )

    ;; Update verifier stats
    (match (map-get? verifier-stats verifier)
      existing-verifier (map-set verifier-stats verifier
        {
          total-verifications: (+ (get total-verifications existing-verifier) u1),
          verifier-since: (get verifier-since existing-verifier)
        }
      )
      ;; First verification by this verifier
      (map-set verifier-stats verifier
        {
          total-verifications: u1,
          verifier-since: block-height
        }
      )
    )

    (ok true)
  )
)

;; Update verification reward (owner only)
(define-public (set-verification-reward (new-reward uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set verification-reward new-reward)
    (ok true)
  )
)

;; read only functions

;; Get sighting details
(define-read-only (get-sighting (sighting-id uint))
  (map-get? sightings sighting-id)
)

;; Get species information
(define-read-only (get-species-info (species-name (string-ascii 100)))
  (map-get? species-registry species-name)
)

;; Get contributor statistics
(define-read-only (get-contributor-stats (contributor principal))
  (map-get? contributor-stats contributor)
)

;; Get verifier statistics
(define-read-only (get-verifier-stats (verifier principal))
  (map-get? verifier-stats verifier)
)

;; Get total number of unique species
(define-read-only (get-total-species-count)
  (ok (var-get total-species-count))
)

;; Get total number of sightings
(define-read-only (get-total-sightings)
  (ok (var-get sighting-nonce))
)

;; Get current verification reward
(define-read-only (get-verification-reward)
  (ok (var-get verification-reward))
)

;; Check if a sighting is verified
(define-read-only (is-sighting-verified (sighting-id uint))
  (match (map-get? sightings sighting-id)
    sighting (ok (get verified sighting))
    err-not-found
  )
)
