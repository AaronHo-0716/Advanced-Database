-- ============================================================
-- members/member1/queries_adminer.sql
-- OWNER: Member 1
-- Assigned queries: i, ii, iii, iv, v, vi, vii
-- Engine: MS SQL Server (T-SQL).
-- ------------------------------------------------------------
-- ADMINER-READY copy of members/member1/queries.sql.
-- Adminer runs each statement in its own batch, so DECLARE'd
-- variables do not survive into the following SELECT, and the
-- sqlcmd batch separator GO is not valid T-SQL. This file has
-- the parameter values inlined and no GO, so each query can be
-- pasted and run on its own. Edit the literals to re-parameterise.
-- (The canonical, sqlcmd-style file is members/member1/queries.sql.)
-- ============================================================

-- ============================================================
-- (i) Round-trip sailings for given dates, departure port, and
--     arrival port.
--     Params: start='2025-06-01', end='2025-06-30', dep='SIN', arr='SIN'
-- ============================================================
SELECT
    v.[voyage_id],
    s.[ship_code],
    s.[ship_name],
    dep.[port_code]      AS [departure_port],
    dep.[port_name]      AS [departure_port_name],
    arr.[port_code]      AS [arrival_port],
    arr.[port_name]      AS [arrival_port_name],
    v.[departure_datetime],
    v.[arrival_datetime],
    v.[voyage_status]
FROM [VOYAGE] v
JOIN [SHIP] s   ON s.[ship_id]           = v.[ship_id]
JOIN [PORT] dep ON dep.[port_id]         = v.[departure_port_id]
JOIN [PORT] arr ON arr.[port_id]         = v.[arrival_port_id]
WHERE v.[itinerary_type] = 'Round-trip'
  AND dep.[port_code]   = 'SIN'
  AND arr.[port_code]   = 'SIN'
  AND CAST(v.[departure_datetime] AS DATE) BETWEEN '2025-06-01' AND '2025-06-30'
ORDER BY v.[departure_datetime];


-- ============================================================
-- (ii) Ship code, cabin category code, expected revenue per
--      cabin category, and total revenue per ship for a given
--      cruise operator on a single voyage.
--      Params: operator='Royal Caribbean International', voyage_id=1
-- ============================================================
WITH [ShipCategoryCapacity] AS (
    SELECT
        s.[ship_id],
        s.[ship_code],
        c.[category_id],
        SUM(c.[max_occupancy]) AS [total_seats]
    FROM [SHIP] s
    JOIN [CABIN] c ON c.[ship_id] = s.[ship_id]
    GROUP BY s.[ship_id], s.[ship_code], c.[category_id]
)
SELECT
    MAX(cap.[ship_code])                                        AS [ship_code],
    CASE WHEN GROUPING(cc.[category_code]) = 1
         THEN 'SHIP TOTAL'
         ELSE cc.[category_code] END                            AS [category_code],
    SUM(vcf.[adult_fare] * cap.[total_seats])                   AS [expected_revenue]
FROM [VOYAGE] v
JOIN [SHIP] s                  ON s.[ship_id]       = v.[ship_id]
JOIN [CRUISE_OPERATOR] op      ON op.[operator_id]  = s.[operator_id]
JOIN [VOYAGE_CABIN_FARE] vcf   ON vcf.[voyage_id]   = v.[voyage_id]
JOIN [CABIN_CATEGORY] cc       ON cc.[category_id]  = vcf.[category_id]
JOIN [ShipCategoryCapacity] cap
                               ON cap.[ship_id]     = s.[ship_id]
                              AND cap.[category_id] = vcf.[category_id]
WHERE op.[operator_name] = 'Royal Caribbean International'
  AND v.[voyage_id]      = 1
GROUP BY ROLLUP (cc.[category_code])
ORDER BY GROUPING(cc.[category_code]), cc.[category_code];


-- ============================================================
-- (iii) All passenger IDs with the textual description of their
--       reservation status, for a specific cruise operator.
--       Params: operator='Royal Caribbean International'
-- ============================================================
SELECT DISTINCT
    p.[passenger_id],
    p.[full_name],
    rs.[status_name]   AS [reservation_status],
    rs.[description]   AS [status_description]
FROM [PASSENGER] p
JOIN [RESERVATION_PASSENGER] rp ON rp.[passenger_id]    = p.[passenger_id]
JOIN [RESERVATION] r            ON r.[reservation_id]   = rp.[reservation_id]
JOIN [RESERVATION_STATUS] rs    ON rs.[status_id]       = r.[status_id]
JOIN [VOYAGE] v                 ON v.[voyage_id]        = r.[voyage_id]
JOIN [SHIP] s                   ON s.[ship_id]          = v.[ship_id]
JOIN [CRUISE_OPERATOR] op       ON op.[operator_id]     = s.[operator_id]
WHERE op.[operator_name] = 'Royal Caribbean International'
ORDER BY p.[passenger_id];


-- ============================================================
-- (iv) Name of the cruise operator most frequently booked by
--      passengers for a specified departure port in a date range.
--      Params: dep='SIN', start='2025-01-01', end='2025-12-31'
-- ============================================================
SELECT TOP 1 WITH TIES
    op.[operator_name],
    COUNT(*) AS [booking_count]
FROM [RESERVATION] r
JOIN [VOYAGE] v           ON v.[voyage_id]       = r.[voyage_id]
JOIN [PORT] dep           ON dep.[port_id]       = v.[departure_port_id]
JOIN [SHIP] s             ON s.[ship_id]         = v.[ship_id]
JOIN [CRUISE_OPERATOR] op ON op.[operator_id]    = s.[operator_id]
WHERE dep.[port_code] = 'SIN'
  AND CAST(r.[booking_date] AS DATE) BETWEEN '2025-01-01' AND '2025-12-31'
GROUP BY op.[operator_name]
ORDER BY COUNT(*) DESC;


-- ============================================================
-- (v) Per age category, total passengers on a specified voyage
--     operated by a given cruise line, with grand total (ROLLUP).
--     Params: voyage_id=1, operator='Royal Caribbean International'
-- ============================================================
SELECT
    CASE WHEN GROUPING(ac.[category_name]) = 1
         THEN 'GRAND TOTAL'
         ELSE ac.[category_name] END AS [age_category],
    COUNT(*)                         AS [passenger_count]
FROM [RESERVATION_PASSENGER] rp
JOIN [AGE_CATEGORY] ac      ON ac.[age_category_id] = rp.[age_category_id]
JOIN [RESERVATION] r        ON r.[reservation_id]   = rp.[reservation_id]
JOIN [VOYAGE] v             ON v.[voyage_id]        = r.[voyage_id]
JOIN [SHIP] s               ON s.[ship_id]          = v.[ship_id]
JOIN [CRUISE_OPERATOR] op   ON op.[operator_id]     = s.[operator_id]
WHERE v.[voyage_id]      = 1
  AND op.[operator_name] = 'Royal Caribbean International'
GROUP BY ROLLUP (ac.[category_name])
ORDER BY GROUPING(ac.[category_name]), ac.[category_name];


-- ============================================================
-- (vi) Cruise operator offering the maximum number of multi-
--      destination itineraries, with departure and final
--      arrival port names of each such voyage.
--      (No parameters.)
-- ============================================================
WITH [OperatorMD] AS (
    SELECT
        op.[operator_id],
        op.[operator_name],
        COUNT(*) AS [md_count]
    FROM [VOYAGE] v
    JOIN [SHIP] s             ON s.[ship_id]      = v.[ship_id]
    JOIN [CRUISE_OPERATOR] op ON op.[operator_id] = s.[operator_id]
    WHERE v.[itinerary_type] = 'Multi-destination'
    GROUP BY op.[operator_id], op.[operator_name]
),
[Winner] AS (
    SELECT TOP 1 WITH TIES *
    FROM [OperatorMD]
    ORDER BY [md_count] DESC
)
SELECT
    w.[operator_name],
    w.[md_count]            AS [multi_destination_count],
    v.[voyage_id],
    dep.[port_name]         AS [departure_port],
    arr.[port_name]         AS [final_arrival_port],
    v.[departure_datetime],
    v.[arrival_datetime]
FROM [Winner] w
JOIN [SHIP] s   ON s.[operator_id]       = w.[operator_id]
JOIN [VOYAGE] v ON v.[ship_id]           = s.[ship_id]
               AND v.[itinerary_type]    = 'Multi-destination'
JOIN [PORT] dep ON dep.[port_id]         = v.[departure_port_id]
JOIN [PORT] arr ON arr.[port_id]         = v.[arrival_port_id]
ORDER BY w.[operator_name], v.[departure_datetime];


-- ============================================================
-- (vii) BUSINESS QUERY: Cancellation impact per cruise operator.
--       Total reservations, cancellations, refund payout,
--       retained fees, and cancellation rate per operator.
--       (No parameters.)
-- ============================================================
WITH [ResByOp] AS (
    SELECT
        op.[operator_id],
        op.[operator_name],
        COUNT(*) AS [total_reservations]
    FROM [RESERVATION] r
    JOIN [VOYAGE] v           ON v.[voyage_id]    = r.[voyage_id]
    JOIN [SHIP] s             ON s.[ship_id]      = v.[ship_id]
    JOIN [CRUISE_OPERATOR] op ON op.[operator_id] = s.[operator_id]
    GROUP BY op.[operator_id], op.[operator_name]
),
[CancByOp] AS (
    SELECT
        op.[operator_id],
        COUNT(*)                     AS [cancellation_count],
        SUM(c.[refund_amount])       AS [total_refunded],
        SUM(c.[cancellation_fee])    AS [total_fees_retained]
    FROM [CANCELLATION] c
    JOIN [RESERVATION] r      ON r.[reservation_id] = c.[reservation_id]
    JOIN [VOYAGE] v           ON v.[voyage_id]      = r.[voyage_id]
    JOIN [SHIP] s             ON s.[ship_id]        = v.[ship_id]
    JOIN [CRUISE_OPERATOR] op ON op.[operator_id]   = s.[operator_id]
    GROUP BY op.[operator_id]
)
SELECT
    rbo.[operator_name],
    rbo.[total_reservations],
    ISNULL(cbo.[cancellation_count], 0)                              AS [cancellations],
    ISNULL(cbo.[total_refunded],     0.00)                           AS [total_refunded],
    ISNULL(cbo.[total_fees_retained], 0.00)                          AS [fees_retained],
    CAST(
        ISNULL(cbo.[cancellation_count], 0) * 100.0 / rbo.[total_reservations]
        AS DECIMAL(5, 2)
    )                                                                AS [cancellation_rate_pct]
FROM [ResByOp] rbo
LEFT JOIN [CancByOp] cbo ON cbo.[operator_id] = rbo.[operator_id]
ORDER BY [total_refunded] DESC, rbo.[operator_name];
