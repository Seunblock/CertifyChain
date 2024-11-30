;; Course Certificate NFT Smart Contract
;; Implements SIP-009 NFT standard for educational certificates
;; Author: Oluwaseun

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ALREADY_EXISTS (err u101))
(define-constant ERR_INVALID_CERTIFICATE (err u102))
(define-constant ERR_CERTIFICATE_REVOKED (err u103))
(define-constant ERR_INVALID_USER (err u104))
(define-constant ERR_NOT_FOUND (err u105))

;; Define the NFT
(define-non-fungible-token course-certificate uint)

;; Data Variables
(define-data-var certificate-counter uint u0)
(define-data-var contract-paused bool false)

;; Data Maps
(define-map certificate-details uint {
    student-id: (string-utf8 64),
    student-address: principal,
    course-name: (string-utf8 128),
    course-id: (string-utf8 32),
    completion-date: uint,
    expiration-date: (optional uint),
    grade: uint,
    issuer: principal,
    issuer-name: (string-utf8 64),
    valid: bool,
    metadata-uri: (string-utf8 256)
})

(define-map authorized-issuers principal {
    name: (string-utf8 64),
    active: bool,
    total-issued: uint
})

(define-map course-registry (string-utf8 32) {
    name: (string-utf8 128),
    description: (string-utf8 256),
    duration-days: uint,
    created-at: uint
})

;; Private Functions
(define-private (is-contract-owner)
    (is-eq tx-sender CONTRACT_OWNER))

(define-private (is-authorized-issuer)
    (match (map-get? authorized-issuers tx-sender)
        issuer-data (get active issuer-data)
        false))

(define-private (increment-issuer-count (issuer principal))
    (match (map-get? authorized-issuers issuer)
        issuer-data (map-set authorized-issuers 
            issuer
            (merge issuer-data {total-issued: (+ (get total-issued issuer-data) u1)}))
        false))

;; Administrative Functions
(define-public (pause-contract)
    (begin
        (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
        (ok (var-set contract-paused true))))

(define-public (unpause-contract)
    (begin
        (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
        (ok (var-set contract-paused false))))

(define-public (register-course
    (course-id (string-utf8 32))
    (name (string-utf8 128))
    (description (string-utf8 256))
    (duration-days uint))
    (begin
        (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
        (asserts! (is-none (map-get? course-registry course-id)) ERR_ALREADY_EXISTS)
        (ok (map-set course-registry course-id {
            name: name,
            description: description,
            duration-days: duration-days,
            created-at: block-height
        }))))

;; Issuer Management
(define-public (add-authorized-issuer 
    (issuer principal)
    (name (string-utf8 64)))
    (begin
        (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
        (asserts! (is-none (map-get? authorized-issuers issuer)) ERR_ALREADY_EXISTS)
        (ok (map-set authorized-issuers issuer {
            name: name,
            active: true,
            total-issued: u0
        }))))

(define-public (deactivate-issuer (issuer principal))
    (begin
        (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
        (match (map-get? authorized-issuers issuer)
            issuer-data (ok (map-set authorized-issuers 
                issuer 
                (merge issuer-data {active: false})))
            ERR_NOT_FOUND)))

;; Certificate Management
(define-public (issue-certificate
    (student-id (string-utf8 64))
    (student-address principal)
    (course-id (string-utf8 32))
    (grade uint)
    (metadata-uri (string-utf8 256))
    (expiration-date (optional uint)))
    (let 
        ((new-id (+ (var-get certificate-counter) u1))
         (course-data (unwrap! (map-get? course-registry course-id) ERR_NOT_FOUND))
         (issuer-data (unwrap! (map-get? authorized-issuers tx-sender) ERR_NOT_AUTHORIZED)))
        (asserts! (not (var-get contract-paused)) ERR_NOT_AUTHORIZED)
        (asserts! (get active issuer-data) ERR_NOT_AUTHORIZED)
        (asserts! (>= grade u0) ERR_INVALID_CERTIFICATE)
        (asserts! (<= grade u100) ERR_INVALID_CERTIFICATE)
        
        ;; Mint NFT and store certificate details
        (try! (nft-mint? course-certificate new-id student-address))
        (map-set certificate-details new-id {
            student-id: student-id,
            student-address: student-address,
            course-name: (get name course-data),
            course-id: course-id,
            completion-date: block-height,
            expiration-date: expiration-date,
            grade: grade,
            issuer: tx-sender,
            issuer-name: (get name issuer-data),
            valid: true,
            metadata-uri: metadata-uri
        })
        
        ;; Update state
        (var-set certificate-counter new-id)
        (increment-issuer-count tx-sender)
        (ok new-id)))

(define-public (revoke-certificate (certificate-id uint))
    (let ((cert-data (unwrap! (map-get? certificate-details certificate-id) ERR_NOT_FOUND)))
        (asserts! (or 
            (is-contract-owner)
            (is-eq tx-sender (get issuer cert-data))) 
            ERR_NOT_AUTHORIZED)
        (ok (map-set certificate-details certificate-id 
            (merge cert-data {valid: false})))))

;; Read-Only Functions
(define-read-only (get-certificate (certificate-id uint))
    (map-get? certificate-details certificate-id))

(define-read-only (verify-certificate (certificate-id uint))
    (match (map-get? certificate-details certificate-id)
        cert-data (begin
            (asserts! (get valid cert-data) ERR_CERTIFICATE_REVOKED)
            (match (get expiration-date cert-data)
                exp-date (if (> exp-date block-height)
                    (ok true)
                    ERR_CERTIFICATE_REVOKED)
                (ok true)))
        ERR_NOT_FOUND))

(define-read-only (get-issuer-details (issuer principal))
    (map-get? authorized-issuers issuer))

(define-read-only (get-course-details (course-id (string-utf8 32)))
    (map-get? course-registry course-id))

;; SIP-009 NFT Interface Implementation
(define-public (transfer (id uint) (sender principal) (recipient principal))
    (err u1)) ;; Certificates are non-transferable

(define-read-only (get-last-token-id)
    (ok (var-get certificate-counter)))

(define-read-only (get-token-uri (id uint))
    (match (map-get? certificate-details id)
        cert-data (ok (some (get metadata-uri cert-data)))
        (ok none)))

(define-read-only (get-owner (id uint))
    (ok (nft-get-owner? course-certificate id)))