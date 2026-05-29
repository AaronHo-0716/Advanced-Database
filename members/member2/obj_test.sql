-- ============================================================
-- GLCL SYSTEM TEST SUITE - MEMBER 2
-- This script verifies Business Rules, Constraints, and Triggers.
-- Run this AFTER 01_tables, 02_constraints, 03b_objects, and 04_seeder.
-- ============================================================

PRINT '------------------------------------------------------------';
PRINT 'SCENARIO 1: Testing Future Booking Constraint';
PRINT 'Requirement: Booking date cannot be in the future.';
PRINT '------------------------------------------------------------';
-- EXPECTED: This should throw a CHECK CONSTRAINT error.
BEGIN TRY
    INSERT INTO [RESERVATION] (voyage_id, cabin_id, status_id, booking_date)
    VALUES (1, 1, 1, '2099-12-31');
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: System blocked future booking date. Error: ' + ERROR_MESSAGE();
END CATCH;


PRINT '';
PRINT '------------------------------------------------------------';
PRINT 'SCENARIO 2: Testing Automated Infant Fare Calculation';
PRINT 'Requirement: Bedding-based pricing (15% adult vs 50% child).';
PRINT '------------------------------------------------------------';
-- Check base fares for reference
SELECT 'Base Fares' as Info, adult_fare, child_fare 
FROM VOYAGE_CABIN_FARE WHERE voyage_id = 1 AND category_id = 1;

-- Add Infant A: Sharing existing bedding (Expected: 15% of 800 = 120)
INSERT INTO [RESERVATION_PASSENGER] (reservation_id, passenger_id, age_category_id, bedding_type)
VALUES (1, 3, 1, 'Existing Bedding');

-- Add Infant B: Requiring Crib/Cot (Expected: 50% of 400 = 200)
INSERT INTO [RESERVATION_PASSENGER] (reservation_id, passenger_id, age_category_id, bedding_type)
VALUES (1, 3, 1, 'Crib/Cot');

-- Verify results
SELECT [bedding_type], [fare_amount] 
FROM [RESERVATION_PASSENGER] 
WHERE [reservation_id] = 1 AND [age_category_id] = 1;


PRINT '';
PRINT '------------------------------------------------------------';
PRINT 'SCENARIO 3: Testing Teen Safety Trigger';
PRINT 'Requirement: Warning if a minor is in a cabin without an adult.';
PRINT '------------------------------------------------------------';
-- Create a new booking
INSERT INTO [RESERVATION] (voyage_id, cabin_id, status_id, total_amount) 
VALUES (1, 2, 1, 500.00);

-- EXPECTED: Check the 'Messages' tab. It should print a Safety Warning.
INSERT INTO [RESERVATION_PASSENGER] (reservation_id, passenger_id, age_category_id, bedding_type)
VALUES (SCOPE_IDENTITY(), 5, 2, 'Normal');


PRINT '';
PRINT '------------------------------------------------------------';
PRINT 'SCENARIO 4: Testing 48-Hour Cancellation Rule';
PRINT 'Requirement: Forfeit ticket value if cancelled < 48 hours.';
PRINT '------------------------------------------------------------';
-- Case A: Future Trip (Should get refund minus fee)
PRINT 'Testing Future Cancellation...';
EXEC [usp_ProcessCancellation] @ResID = 1, @Reason = 'Change of plans';

-- Case B: Last Minute Trip (Should forfeit total)
PRINT 'Testing Last Minute Cancellation...';
INSERT INTO [VOYAGE] (ship_id, departure_port_id, arrival_port_id, departure_datetime, arrival_datetime, itinerary_type, voyage_status)
VALUES (1, 1, 2, DATEADD(hour, 10, GETDATE()), DATEADD(day, 3, GETDATE()), 'One-way', 'Active');

INSERT INTO [RESERVATION] (voyage_id, cabin_id, status_id, total_amount) 
VALUES (SCOPE_IDENTITY(), 1, 1, 1000.00);

EXEC [usp_ProcessCancellation] @ResID = 2, @Reason = 'Emergency';

-- Verify Cancellation Log
SELECT [reservation_id], [cancellation_fee], [refund_amount], [reason] 
FROM [CANCELLATION];


PRINT '';
PRINT '------------------------------------------------------------';
PRINT 'SCENARIO 5: Testing 1-Year Reschedule Rule';
PRINT 'Requirement: New voyage must start within 1 year of original booking.';
PRINT '------------------------------------------------------------';
-- Case A: Reschedule to the year 2030 (Expected: FAIL)
BEGIN TRY
    EXEC [usp_RescheduleVoyage] @ResID = 2, @NewVoyageID = 6; 
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: System blocked invalid reschedule date. Error: ' + ERROR_MESSAGE();
END CATCH;

-- Case B: Reschedule to a valid date (Expected: PASS)
EXEC [usp_RescheduleVoyage] @ResID = 2, @NewVoyageID = 2;

-- Verify change
SELECT [reservation_id], [voyage_id], [status_id] 
FROM [RESERVATION] WHERE [reservation_id] = 2;

PRINT '------------------------------------------------------------';
PRINT 'MEMBER 2 TEST SUITE COMPLETE';
PRINT '------------------------------------------------------------';