-- ============================================================
-- members/member3/queries.sql
-- OWNER: Member 3
-- Assigned queries: xv, xvi, xvii, xviii, xix, xx, xxi
-- Engine: MS SQL Server (T-SQL).
-- ------------------------------------------------------------
-- Run individually from your GUI client (Azure Data Studio /
-- DBeaver / SSMS) against the `glcl` database after running
-- reset.sh / reset.ps1.
-- ============================================================

-- xv. Minimum, maximum, and average voyage duration in days
-- for sailings to a given destination port code.
DECLARE @DestinationPortCode VARCHAR(10) = 'PEN';

SELECT
    MIN(DATEDIFF(MINUTE, v.departure_datetime, v.arrival_datetime) / 1440.0) AS [Minimum Duration],
    MAX(DATEDIFF(MINUTE, v.departure_datetime, v.arrival_datetime) / 1440.0) AS [Maximum Duration],
    AVG(DATEDIFF(MINUTE, v.departure_datetime, v.arrival_datetime) / 1440.0) AS [Average Duration]
FROM [VOYAGE] v
INNER JOIN [PORT] p
    ON v.arrival_port_id = p.port_id
WHERE p.port_code = @DestinationPortCode;
GO

-- xvi. Departure date, number of booked passengers in the party,
-- and cabin category name for a specified passenger ID.
DECLARE @PassengerID INT = 1;

SELECT
    CAST(v.departure_datetime AS DATE) AS departure_date,
    COUNT(rp_all.reservation_passenger_id) AS booked_passengers_in_party,
    cc.category_name AS cabin_category_name
FROM [RESERVATION_PASSENGER] rp_target
INNER JOIN [RESERVATION] r
    ON rp_target.reservation_id = r.reservation_id
INNER JOIN [VOYAGE] v
    ON r.voyage_id = v.voyage_id
INNER JOIN [CABIN] c
    ON r.cabin_id = c.cabin_id
INNER JOIN [CABIN_CATEGORY] cc
    ON c.category_id = cc.category_id
INNER JOIN [RESERVATION_PASSENGER] rp_all
    ON r.reservation_id = rp_all.reservation_id
WHERE rp_target.passenger_id = @PassengerID
GROUP BY
    v.departure_datetime,
    cc.category_name,
    r.reservation_id;
GO

-- xvii. Excursions with no sales.
SELECT
    e.excursion_id,
    e.excursion_name,
    p.port_name,
    e.price
FROM [EXCURSION] e
INNER JOIN [PORT] p
    ON e.port_id = p.port_id
LEFT JOIN [VOYAGE_EXCURSION] ve
    ON e.excursion_id = ve.excursion_id
LEFT JOIN [EXCURSION_BOOKING] eb
    ON ve.voyage_excursion_id = eb.voyage_excursion_id
WHERE eb.excursion_booking_id IS NULL;
GO

-- xviii. Passenger details for a specified cruise operator on a
-- given departure date for multi-destination itineraries.
-- Note: the original seed data has a multi-destination voyage but no
-- reservation for it, so this may return no rows unless test data is added.
DECLARE @OperatorName VARCHAR(100) = 'Carnival Cruise Line';
DECLARE @GivenDate DATE = '2025-08-01';

SELECT
    co.operator_name,
    s.ship_name,
    v.voyage_id,
    CAST(v.departure_datetime AS DATE) AS departure_date,
    v.itinerary_type,
    p.passenger_id,
    p.full_name,
    p.passport_no,
    p.nationality,
    r.reservation_id,
    c.cabin_no
FROM [CRUISE_OPERATOR] co
INNER JOIN [SHIP] s
    ON co.operator_id = s.operator_id
INNER JOIN [VOYAGE] v
    ON s.ship_id = v.ship_id
INNER JOIN [RESERVATION] r
    ON v.voyage_id = r.voyage_id
INNER JOIN [RESERVATION_PASSENGER] rp
    ON r.reservation_id = rp.reservation_id
INNER JOIN [PASSENGER] p
    ON rp.passenger_id = p.passenger_id
INNER JOIN [CABIN] c
    ON r.cabin_id = c.cabin_id
WHERE co.operator_name = @OperatorName
  AND CAST(v.departure_datetime AS DATE) = @GivenDate
  AND v.itinerary_type = 'Multi-destination'
ORDER BY
    v.voyage_id,
    r.reservation_id,
    p.full_name;
GO

-- xix. Wheelchair assistance passenger counts by cruise operator
-- on a given travel date, with ship-level detail, operator summaries,
-- and an overall summary using ROLLUP.
DECLARE @TravelDate DATE = '2025-06-01';

SELECT
    CASE
        WHEN GROUPING(co.operator_name) = 1 THEN 'Overall Summary'
        ELSE co.operator_name
    END AS cruise_operator,
    CASE
        WHEN GROUPING(s.ship_name) = 1 AND GROUPING(co.operator_name) = 0 THEN 'Operator Summary'
        WHEN GROUPING(s.ship_name) = 1 AND GROUPING(co.operator_name) = 1 THEN 'All Ships'
        ELSE s.ship_name
    END AS ship_name,
    COUNT(rp.reservation_passenger_id) AS wheelchair_passenger_count
FROM [CRUISE_OPERATOR] co
INNER JOIN [SHIP] s
    ON co.operator_id = s.operator_id
INNER JOIN [VOYAGE] v
    ON s.ship_id = v.ship_id
INNER JOIN [RESERVATION] r
    ON v.voyage_id = r.voyage_id
INNER JOIN [RESERVATION_PASSENGER] rp
    ON r.reservation_id = rp.reservation_id
WHERE rp.requires_wheelchair_assistance = 1
  AND @TravelDate BETWEEN CAST(v.departure_datetime AS DATE)
                      AND CAST(v.arrival_datetime AS DATE)
GROUP BY ROLLUP(co.operator_name, s.ship_name)
ORDER BY
    GROUPING(co.operator_name),
    co.operator_name,
    GROUPING(s.ship_name),
    s.ship_name;
GO

-- xx. Details of passengers who have availed of the Chaperoned Youth
-- extra service for a given sailing on a specified date.
-- This version follows Member 3's final design where the program is
-- recorded in YOUTH_TRAVEL_ARRANGEMENT.
DECLARE @VoyageID INT = 1;
DECLARE @DepartureDate DATE = '2025-06-01';

SELECT
    v.voyage_id,
    CAST(v.departure_datetime AS DATE) AS departure_date,
    p.passenger_id,
    p.full_name,
    p.date_of_birth,
    yta.arrangement_type,
    yta.supervision_fee AS recorded_supervision_fee,
    dbo.fn_CalculateChaperonedYouthFee(yta.reservation_passenger_id) AS calculated_supervision_fee
FROM [YOUTH_TRAVEL_ARRANGEMENT] yta
INNER JOIN [RESERVATION_PASSENGER] rp
    ON yta.reservation_passenger_id = rp.reservation_passenger_id
INNER JOIN [PASSENGER] p
    ON rp.passenger_id = p.passenger_id
INNER JOIN [RESERVATION] r
    ON rp.reservation_id = r.reservation_id
INNER JOIN [VOYAGE] v
    ON r.voyage_id = v.voyage_id
WHERE yta.arrangement_type = 'Chaperoned Youth Program'
  AND v.voyage_id = @VoyageID
  AND CAST(v.departure_datetime AS DATE) = @DepartureDate;
GO

-- xxi. Additional business query: revenue by cabin category for each voyage.
-- This helps GLCL compare booking volume and passenger fare revenue by cabin type.
SELECT
    v.voyage_id,
    s.ship_name,
    CAST(v.departure_datetime AS DATE) AS departure_date,
    cc.category_name,
    COUNT(DISTINCT r.reservation_id) AS total_reservations,
    COUNT(rp.reservation_passenger_id) AS total_passengers,
    SUM(rp.fare_amount) AS total_passenger_fare
FROM [VOYAGE] v
INNER JOIN [SHIP] s
    ON v.ship_id = s.ship_id
INNER JOIN [RESERVATION] r
    ON v.voyage_id = r.voyage_id
INNER JOIN [CABIN] c
    ON r.cabin_id = c.cabin_id
INNER JOIN [CABIN_CATEGORY] cc
    ON c.category_id = cc.category_id
INNER JOIN [RESERVATION_PASSENGER] rp
    ON r.reservation_id = rp.reservation_id
GROUP BY
    v.voyage_id,
    s.ship_name,
    v.departure_datetime,
    cc.category_name
ORDER BY
    v.voyage_id,
    cc.category_name;
GO
