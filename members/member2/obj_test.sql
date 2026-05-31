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
    PRINT 'SUCCESS: System blocked future booking date.'
END CATCH;


PRINT '============================================================';
PRINT 'SCENARIO 2: ISOLATED INFANT FARE TEST';
PRINT '============================================================';

-- STEP 1: CREATE NEW CLEAN RESERVATION FOR TEST
DECLARE @TestResID INT;

INSERT INTO RESERVATION (voyage_id, cabin_id, status_id, booking_date, total_amount)
VALUES (1, 1, 1, GETDATE(), 3000);

SET @TestResID = SCOPE_IDENTITY();

-- STEP 2: SHOW BASE FARE
SELECT adult_fare, child_fare
FROM VOYAGE_CABIN_FARE
WHERE voyage_id = 1 AND category_id = 1;

-- STEP 3: TEST CASE 1 (Existing Bedding)
INSERT INTO RESERVATION_PASSENGER (reservation_id, passenger_id, age_category_id, bedding_type)
VALUES (@TestResID, 3, 1, 'Existing Bedding');

-- STEP 4: TEST CASE 2 (Crib/Cot)
INSERT INTO RESERVATION_PASSENGER (reservation_id, passenger_id, age_category_id, bedding_type)
VALUES (@TestResID, 4, 1, 'Crib/Cot');

-- STEP 5: VERIFY ONLY TEST DATA
SELECT bedding_type, fare_amount
FROM RESERVATION_PASSENGER
WHERE reservation_id = @TestResID;


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


PRINT 'SCENARIO 4: 48-HOUR CANCELLATION RULE TEST';

-- CASE A: Future cancellation (>48 hours) (Should get refund minus fee)
DECLARE @VoyageA INT, @ResA INT;

INSERT INTO VOYAGE
(ship_id, departure_port_id, arrival_port_id, departure_datetime, arrival_datetime, itinerary_type, voyage_status)
VALUES
(1, 1, 2, DATEADD(day, 10, GETDATE()), DATEADD(day, 12, GETDATE()), 'One-way', 'Active');

SET @VoyageA = SCOPE_IDENTITY();

INSERT INTO RESERVATION (voyage_id, cabin_id, status_id, total_amount)
VALUES (@VoyageA, 1, 1, 1000);

SET @ResA = SCOPE_IDENTITY();

EXEC usp_ProcessCancellation @ResA, 'Case A';

-- CASE B: Last-minute cancellation (<48 hours)
DECLARE @VoyageB INT, @ResB INT;

INSERT INTO VOYAGE
(ship_id, departure_port_id, arrival_port_id, departure_datetime, arrival_datetime, itinerary_type, voyage_status)
VALUES
(1, 1, 2, DATEADD(hour, 10, GETDATE()), DATEADD(day, 1, GETDATE()), 'One-way', 'Active');

SET @VoyageB = SCOPE_IDENTITY();

INSERT INTO RESERVATION (voyage_id, cabin_id, status_id, total_amount)
VALUES (@VoyageB, 1, 1, 2000);

SET @ResB = SCOPE_IDENTITY();

EXEC usp_ProcessCancellation @ResB, 'Case B';

-- RESULT CHECK
SELECT reservation_id, cancellation_fee, refund_amount, reason
FROM CANCELLATION
WHERE reason IN ('Case A', 'Case B');


PRINT 'SCENARIO 5: 1-YEAR RESCHEDULE RULE TEST';

-- CASE A: INVALID RESCHEDULE (>1 year → should FAIL)
PRINT 'CASE A: Invalid Reschedule (Expected: FAIL)';

BEGIN TRY
    EXEC usp_RescheduleVoyage @ResID = 2, @NewVoyageID = 9; -- 2030 voyage
    PRINT 'ERROR: Case A should have failed but passed!';
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: Case A blocked. ' + ERROR_MESSAGE();
END CATCH;

-- CASE B: VALID RESCHEDULE (Expected: PASS)
PRINT 'CASE B: Valid Reschedule (Expected: PASS)';

EXEC usp_RescheduleVoyage @ResID = 2, @NewVoyageID = 2;

-- VERIFY RESULT
SELECT reservation_id, voyage_id, status_id
FROM RESERVATION
WHERE reservation_id = 2;

PRINT '------------------------------------------------------------';
PRINT 'MEMBER 2 TEST SUITE COMPLETE';
PRINT '------------------------------------------------------------';
