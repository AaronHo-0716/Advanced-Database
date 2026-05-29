-- ============================================================
-- members/member2/queries.sql
-- OWNER: Member 2
-- Assigned queries: viii, ix, x, xi, xii, xiii, xiv
-- Engine: MS SQL Server (T-SQL).
-- ------------------------------------------------------------
-- Run individually from your GUI client (Azure Data Studio /
-- DBeaver / SSMS) against the `glcl` database after running
-- reset.sh / reset.ps1.
-- ============================================================

-- viii. Display Suite sailing details with 15% Early Bird discount
SELECT 
    S.[ship_code] AS [Ship Code],
    VCF.[adult_fare] AS [Regular Suite Fare],
    (VCF.[adult_fare] * 0.85) AS [Discounted Suite Fare]
FROM [VOYAGE_CABIN_FARE] VCF
JOIN [VOYAGE] V ON VCF.[voyage_id] = V.[voyage_id]
JOIN [SHIP] S ON V.[ship_id] = S.[ship_id]
JOIN [CABIN_CATEGORY] CC ON VCF.[category_id] = CC.[category_id]
WHERE CC.[category_name] = 'Suite';


-- ix. Sailings to a given destination (e.g., 'HKG'), shortest duration first
SELECT 
    V.[voyage_id],
    V.[departure_datetime],
    V.[arrival_datetime],
    DATEDIFF(HOUR, V.[departure_datetime], V.[arrival_datetime]) AS [DurationHours]
FROM [VOYAGE] V
JOIN [PORT] P ON V.[arrival_port_id] = P.[port_id]
WHERE P.[port_code] = 'HKG'
ORDER BY [DurationHours] ASC;


-- x. Specialty dining options offered on specific ships
SELECT 
    S.[ship_name],
    DO.[option_name],
    DO.[option_type]
FROM [SHIP_DINING_OPTION] SDO
JOIN [SHIP] S ON SDO.[ship_id] = S.[ship_id]
JOIN [DINING_OPTION] DO ON SDO.[dining_option_id] = DO.[dining_option_id]
WHERE DO.[option_type] = 'Specialty';


-- xi. Unique names of countries where GLCL ships dock
SELECT DISTINCT P.[country]
FROM [PORT] P
JOIN [VOYAGE] V ON (V.[departure_port_id] = P.[port_id] OR V.[arrival_port_id] = P.[port_id])
UNION
SELECT DISTINCT P.[country]
FROM [ITINERARY_STOP] ITS
JOIN [PORT] P ON ITS.[port_id] = P.[port_id];


-- xii. Total voyages per operator on a given date with breakup/summary (ROLLUP)
-- Note: '2025-06-01' used as the test departure date
SELECT 
    CO.[operator_name],
    V.[voyage_id],
    COUNT(V.[voyage_id]) AS [VoyageCount]
FROM [CRUISE_OPERATOR] CO
JOIN [SHIP] S ON CO.[operator_id] = S.[operator_id]
JOIN [VOYAGE] V ON S.[ship_id] = V.[ship_id]
WHERE CAST(V.[departure_datetime] AS DATE) = '2025-06-01'
GROUP BY ROLLUP(CO.[operator_name], V.[voyage_id]);


-- xiii. Onshore excursion options available for a given ship's itinerary
-- Example for Ship ID 1
SELECT DISTINCT
    S.[ship_name],
    E.[excursion_name],
    E.[price]
FROM [SHIP] S
JOIN [VOYAGE] V ON S.[ship_id] = V.[ship_id]
JOIN [VOYAGE_EXCURSION] VE ON V.[voyage_id] = VE.[voyage_id]
JOIN [EXCURSION] E ON VE.[excursion_id] = E.[excursion_id]
WHERE S.[ship_id] = 1;


-- xiv. Additional Query: Top 3 most popular cabin categories based on reservation count
SELECT TOP 3
    CC.[category_name],
    COUNT(R.[reservation_id]) AS [BookingCount]
FROM [CABIN_CATEGORY] CC
JOIN [CABIN] C ON CC.[category_id] = C.[category_id]
JOIN [RESERVATION] R ON C.[cabin_id] = R.[cabin_id]
GROUP BY CC.[category_name]
ORDER BY [BookingCount] DESC;
