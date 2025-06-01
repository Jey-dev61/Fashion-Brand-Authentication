;; Fashion Brand Authentication Contract
;; Provides brand verification and anti-counterfeiting measures

(define-data-var next-product-id uint u1)
(define-data-var next-brand-id uint u1)
(define-data-var contract-owner principal tx-sender)

(define-map registered-brands uint {
  owner: principal,
  name: (string-ascii 64),
  verified: bool,
  registration-time: uint,
  products-count: uint
})

(define-map brand-owners principal uint)

(define-map authenticated-products uint {
  brand-id: uint,
  product-name: (string-ascii 64),
  product-code: (string-ascii 32),
  manufacture-date: uint,
  authentication-hash: (buff 32),
  verified: bool
})

(define-map product-ownership uint principal)

(define-map counterfeit-reports uint {
  reporter: principal,
  product-id: uint,
  report-time: uint,
  verified: bool,
  reward-claimed: bool
})

(define-map user-rewards principal uint)

(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-ALREADY-EXISTS (err u409))
(define-constant ERR-NOT-VERIFIED (err u403))

(define-constant COUNTERFEIT-REWARD u100000)

(define-public (register-brand (name (string-ascii 64)))
  (let ((brand-id (var-get next-brand-id)))
    (asserts! (is-none (map-get? brand-owners tx-sender)) ERR-ALREADY-EXISTS)
    (map-set registered-brands brand-id {
      owner: tx-sender,
      name: name,
      verified: false,
      registration-time: block-height,
      products-count: u0
    })
    (map-set brand-owners tx-sender brand-id)
    (var-set next-brand-id (+ brand-id u1))
    (ok brand-id)))

(define-public (verify-brand (brand-id uint))
  (let ((brand (unwrap! (map-get? registered-brands brand-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (map-set registered-brands brand-id (merge brand {verified: true}))
    (ok true)))

(define-public (authenticate-product
  (product-name (string-ascii 64))
  (product-code (string-ascii 32))
  (authentication-hash (buff 32)))
  (let ((brand-id (unwrap! (map-get? brand-owners tx-sender) ERR-NOT-FOUND))
        (brand (unwrap! (map-get? registered-brands brand-id) ERR-NOT-FOUND))
        (product-id (var-get next-product-id)))
    (asserts! (get verified brand) ERR-NOT-VERIFIED)
    (map-set authenticated-products product-id {
      brand-id: brand-id,
      product-name: product-name,
      product-code: product-code,
      manufacture-date: block-height,
      authentication-hash: authentication-hash,
      verified: true
    })
    (map-set product-ownership product-id tx-sender)
    (map-set registered-brands brand-id (merge brand {
      products-count: (+ (get products-count brand) u1)
    }))
    (var-set next-product-id (+ product-id u1))
    (ok product-id)))

(define-public (verify-product-authenticity (product-id uint) (provided-hash (buff 32)))
  (let ((product (unwrap! (map-get? authenticated-products product-id) ERR-NOT-FOUND)))
    (ok (is-eq (get authentication-hash product) provided-hash))))

(define-public (report-counterfeit (product-id uint))
  (let ((report-id product-id))
    (map-set counterfeit-reports report-id {
      reporter: tx-sender,
      product-id: product-id,
      report-time: block-height,
      verified: false,
      reward-claimed: false
    })
    (ok report-id)))

(define-public (verify-counterfeit-report (report-id uint))
  (let ((report (unwrap! (map-get? counterfeit-reports report-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (map-set counterfeit-reports report-id (merge report {verified: true}))
    (let ((reporter (get reporter report))
          (current-rewards (default-to u0 (map-get? user-rewards reporter))))
      (map-set user-rewards reporter (+ current-rewards COUNTERFEIT-REWARD)))
    (ok true)))

(define-public (claim-counterfeit-reward (report-id uint))
  (let ((report (unwrap! (map-get? counterfeit-reports report-id) ERR-NOT-FOUND)))
    (asserts! (is-eq (get reporter report) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (get verified report) ERR-NOT-VERIFIED)
    (asserts! (not (get reward-claimed report)) ERR-ALREADY-EXISTS)
    (try! (as-contract (stx-transfer? COUNTERFEIT-REWARD tx-sender tx-sender)))
    (map-set counterfeit-reports report-id (merge report {reward-claimed: true}))
    (ok true)))

(define-public (transfer-product-ownership (product-id uint) (new-owner principal))
  (let ((current-owner (unwrap! (map-get? product-ownership product-id) ERR-NOT-FOUND)))
    (asserts! (is-eq current-owner tx-sender) ERR-NOT-AUTHORIZED)
    (map-set product-ownership product-id new-owner)
    (ok true)))

(define-read-only (get-brand-info (brand-id uint))
  (map-get? registered-brands brand-id))

(define-read-only (get-product-info (product-id uint))
  (map-get? authenticated-products product-id))

(define-read-only (get-product-owner (product-id uint))
  (map-get? product-ownership product-id))

(define-read-only (get-user-brand (user principal))
  (map-get? brand-owners user))

(define-read-only (get-user-rewards (user principal))
  (default-to u0 (map-get? user-rewards user)))

(define-read-only (check-product-authenticity (product-id uint))
  (let ((product (map-get? authenticated-products product-id)))
    (match product
      prod (ok {
        authentic: (get verified prod),
        brand-id: (get brand-id prod),
        manufacture-date: (get manufacture-date prod)
      })
      (ok {authentic: false, brand-id: u0, manufacture-date: u0}))))
      