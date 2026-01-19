(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))

(define-map kpi-metrics
  { metric-id: uint }
  {
    metric-name: (string-ascii 100),
    current-value: uint,
    target-value: uint,
    unit: (string-ascii 30),
    last-updated: uint,
    status: (string-ascii 20)
  }
)

(define-map real-time-monitoring
  { location-id: principal, timestamp: uint }
  {
    inventory-level: uint,
    throughput-rate: uint,
    utilization-percent: uint,
    exception-count: uint,
    performance-score: uint
  }
)

(define-map exception-alerts
  { alert-id: uint }
  {
    severity: (string-ascii 20),
    location-id: principal,
    alert-message: (string-ascii 200),
    created-at: uint,
    acknowledged: bool
  }
)

(define-map executive-reports
  { report-id: uint }
  {
    period-start: uint,
    period-end: uint,
    total-throughput: uint,
    avg-utilization: uint,
    cost-per-unit: uint,
    on-time-delivery-percent: uint
  }
)

(define-data-var next-metric-id uint u1)
(define-data-var next-alert-id uint u1)
(define-data-var next-report-id uint u1)

(define-public (register-kpi (name (string-ascii 100)) (target uint) (unit (string-ascii 30)))
  (let ((metric-id (var-get next-metric-id)))
    (begin
      (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
      (map-set kpi-metrics
        { metric-id: metric-id }
        {
          metric-name: name,
          current-value: u0,
          target-value: target,
          unit: unit,
          last-updated: u0,
          status: "active"
        }
      )
      (var-set next-metric-id (+ metric-id u1))
      (ok metric-id)
    )
  )
)

(define-public (update-kpi-value (metric-id uint) (value uint))
  (if (is-eq tx-sender CONTRACT-OWNER)
    (let ((kpi (map-get? kpi-metrics { metric-id: metric-id })))
      (if (is-some kpi)
        (let ((current (unwrap-panic kpi))
              (status (if (>= value (get target-value current)) "on-target" "below-target")))
          (begin
            (map-set kpi-metrics
              { metric-id: metric-id }
              (merge current {
                current-value: value,
                last-updated: u0,
                status: status
              })
            )
            (ok true)
          )
        )
        (err ERR-NOT-FOUND)
      )
    )
    (err ERR-NOT-AUTHORIZED)
  )
)

(define-public (log-monitoring-data (location-id principal) (inventory uint) (throughput uint) (utilization uint) (exceptions uint) (score uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set real-time-monitoring
      { location-id: location-id, timestamp: u0 }
      {
        inventory-level: inventory,
        throughput-rate: throughput,
        utilization-percent: utilization,
        exception-count: exceptions,
        performance-score: score
      }
    )
    (ok true)
  )
)

(define-public (create-exception-alert (severity (string-ascii 20)) (location-id principal) (message (string-ascii 200)))
  (let ((alert-id (var-get next-alert-id)))
    (begin
      (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
      (map-set exception-alerts
        { alert-id: alert-id }
        {
          severity: severity,
          location-id: location-id,
          alert-message: message,
          created-at: u0,
          acknowledged: false
        }
      )
      (var-set next-alert-id (+ alert-id u1))
      (ok alert-id)
    )
  )
)

(define-public (generate-executive-report (start uint) (end uint) (throughput uint) (util uint) (cost uint) (delivery uint))
  (let ((report-id (var-get next-report-id)))
    (begin
      (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
      (map-set executive-reports
        { report-id: report-id }
        {
          period-start: start,
          period-end: end,
          total-throughput: throughput,
          avg-utilization: util,
          cost-per-unit: cost,
          on-time-delivery-percent: delivery
        }
      )
      (var-set next-report-id (+ report-id u1))
      (ok report-id)
    )
  )
)

(define-read-only (get-kpi (metric-id uint))
  (map-get? kpi-metrics { metric-id: metric-id })
)

(define-read-only (get-alert (alert-id uint))
  (map-get? exception-alerts { alert-id: alert-id })
)

(define-read-only (get-report (report-id uint))
  (map-get? executive-reports { report-id: report-id })
)
