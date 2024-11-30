;; Course Certificate NFT Contract
;; Implements SIP-009 NFT standard with additional certificate metadata

(define-non-fungible-token certificate uint)

;; Data Maps
(define-map certificate-data uint {
    student-id: (string-utf8 64),
    course-name: (string-utf8 128),
    completion-date: uint,
    grade: uint,
    issuer: principal,
    valid: bool,
    metadata-uri: (string-utf8 256)
})

(define-map authorized-issuers principal bool)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-certificate (err u101))
(define-constant err-certificate-exists (err u102))

;; State Variables
(define-data-var certificate-counter uint u0)

;; Authorization
(define-public (add-authorized-issuer (issuer principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
        (ok (map-set authorized-issuers issuer true))))

(define-public (remove-authorized-issuer (issuer principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
        (ok (map-set authorized-issuers issuer false))))

;; Core Functions
(define-public (issue-certificate 
    (student-id (string-utf8 64))
    (course-name (string-utf8 128))
    (grade uint)
    (metadata-uri (string-utf8 256)))
    (let ((new-id (+ (var-get certificate-counter) u1)))
        (asserts! (is-some (map-get? authorized-issuers tx-sender)) err-not-authorized)
        (try! (nft-mint? certificate new-id tx-sender))
        (map-set certificate-data new-id {
            student-id: student-id,
            course-name: course-name,
            completion-date: block-height,
            grade: grade,
            issuer: tx-sender,
            valid: true,
            metadata-uri: metadata-uri
        })
        (var-set certificate-counter new-id)
        (ok new-id)))

(define-public (revoke-certificate (certificate-id uint))
    (let ((cert-data (unwrap! (map-get? certificate-data certificate-id) err-invalid-certificate)))
        (asserts! (or 
            (is-eq tx-sender contract-owner)
            (is-eq tx-sender (get issuer cert-data))) 
            err-not-authorized)
        (ok (map-set certificate-data certificate-id 
            (merge cert-data { valid: false })))))

;; Read Functions
(define-read-only (get-certificate-data (certificate-id uint))
    (map-get? certificate-data certificate-id))

(define-read-only (verify-certificate (certificate-id uint))
    (match (map-get? certificate-data certificate-id)
        cert-data (ok (get valid cert-data))
        (err err-invalid-certificate)))

;; SIP-009 NFT Interface Implementation
(define-public (transfer (id uint) (sender principal) (recipient principal))
    (err u1)) ;; Certificates are non-transferable

(define-read-only (get-last-token-id)
    (ok (var-get certificate-counter)))

(define-read-only (get-token-uri (id uint))
    (match (map-get? certificate-data id)
        cert-data (ok (some (get metadata-uri cert-data)))
        (ok none)))

(define-read-only (get-owner (id uint))
    (ok (nft-get-owner? certificate id)))