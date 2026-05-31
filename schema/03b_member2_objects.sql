-- ============================================================
-- 03b_member2_objects.sql
-- OWNER: Member 2
-- Engine: MS SQL Server (T-SQL).
-- ------------------------------------------------------------
-- Contents required by the assignment:
--   1. CHECK constraints (Data Integrity)
--   2. Triggers (Business Rule Automation)
--   3. Stored Procedures (Operational Logic)
--   4. Optimization Strategy (Requirement 1b - Indexing)
-- ============================================================

-- ------------------------------------------------------------
-- 1. CONSTRAINTS (Requirement 1c)
-- ------------------------------------------------------------

-- Business Rule: Booking date cannot be in the future.
ALTER TABLE [RESERVATION]
ADD CONSTRAINT [CHK_BOOKING_DATE_VALID] 
CHECK ([booking_date] <= GETDATE());
GO

-- Business Rule: A reschedule request cannot be logged for a future date/time.
ALTER TABLE [RESCHEDULE]
ADD CONSTRAINT [CHK_RESCHEDULE_NOT_FUTURE] 
CHECK ([request_datetime] <= GETDATE());
GO


-- ------------------------------------------------------------
-- 2. TRIGGERS (Requirement 1c / 2b)
-- ------------------------------------------------------------

-- Business Rule: "Infant sharing bedding = 15% of adult fare; 
--                 Infant requiring crib = 50% of child fare."
CREATE OR ALTER TRIGGER [trg_CalculateInfantFare]
ON [RESERVATION_PASSENGER]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE RP
    SET [fare_amount] = CASE 
        WHEN i.[bedding_type] = 'Existing Bedding' THEN (VCF.[adult_fare] * 0.15)
        WHEN i.[bedding_type] = 'Crib/Cot' THEN (VCF.[child_fare] * 0.50)
        ELSE RP.[fare_amount]
    END
    FROM [RESERVATION_PASSENGER] RP
    JOIN inserted i ON RP.[reservation_passenger_id] = i.[reservation_passenger_id]
    JOIN [RESERVATION] R ON RP.[reservation_id] = R.[reservation_id]
    JOIN [VOYAGE_CABIN_FARE] VCF ON R.[voyage_id] = VCF.[voyage_id]
    JOIN [CABIN] C ON R.[cabin_id] = C.[cabin_id] AND VCF.[category_id] = C.[category_id]
    WHERE i.[age_category_id] = 1;
END;
GO

-- Safety Rule: "A teen (up to 17) cannot travel in a cabin alone unless an adult is booked."
CREATE OR ALTER TRIGGER [trg_ValidateAdultPresence]
ON [RESERVATION_PASSENGER]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT [reservation_id] 
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1 FROM [RESERVATION_PASSENGER] rp 
            WHERE rp.[reservation_id] = i.[reservation_id] 
            AND rp.[age_category_id] IN (4, 5) -- Adult or Senior
        )
    )
    BEGIN
        PRINT 'WARNING: Every cabin must have at least one Adult (18+) or Senior (60+).';
    END
END;
GO


-- ------------------------------------------------------------
-- 3. STORED PROCEDURES (Requirement 2c)
-- ------------------------------------------------------------

-- Business Rule: 48-hour cancellation forfeit rule.
CREATE OR ALTER PROCEDURE [usp_ProcessCancellation]
    @ResID INT,
    @Reason VARCHAR(255)
AS
BEGIN
    DECLARE @DepTime DATETIME, @Total DECIMAL(18,2), @Refund DECIMAL(18,2), @Fee DECIMAL(18,2);

    SELECT @DepTime = V.[departure_datetime], @Total = R.[total_amount]
    FROM [RESERVATION] R JOIN [VOYAGE] V ON R.[voyage_id] = V.[voyage_id]
    WHERE R.[reservation_id] = @ResID;

    IF DATEDIFF(HOUR, GETDATE(), @DepTime) < 48
    BEGIN
        SET @Refund = 0; SET @Fee = @Total;
    END
    ELSE
    BEGIN
        SET @Fee = 150.00;
        SET @Refund = @Total - @Fee;
    END

    INSERT INTO [CANCELLATION] ([reservation_id], [cancellation_fee], [refund_amount], [reason])
    VALUES (@ResID, @Fee, @Refund, @Reason);

    UPDATE [RESERVATION] SET [status_id] = 3 WHERE [reservation_id] = @ResID;
END;
GO

-- Business Rule: 1-year rescheduling transfer limit.
CREATE OR ALTER PROCEDURE [usp_RescheduleVoyage]
    @ResID INT,
    @NewVoyageID INT
AS
BEGIN
    DECLARE @BookingDate DATETIME, @NewDepDate DATETIME;

    SELECT @BookingDate = [booking_date] FROM [RESERVATION] WHERE [reservation_id] = @ResID;
    SELECT @NewDepDate = [departure_datetime] FROM [VOYAGE] WHERE [voyage_id] = @NewVoyageID;

    IF @NewDepDate > DATEADD(YEAR, 1, @BookingDate)
    BEGIN
        RAISERROR('Rescheduling Failed: New voyage must start within 1 year.', 16, 1);
        RETURN;
    END

    INSERT INTO [RESCHEDULE] ([reservation_id], [old_voyage_id], [new_voyage_id], [status])
    SELECT [reservation_id], [voyage_id], @NewVoyageID, 'Approved'
    FROM [RESERVATION] WHERE [reservation_id] = @ResID;

    UPDATE [RESERVATION] SET [voyage_id] = @NewVoyageID, [status_id] = 4 WHERE [reservation_id] = @ResID;
END;
GO


-- ------------------------------------------------------------
-- 4. OPTIMIZATION STRATEGY (Requirement 1b)
-- ------------------------------------------------------------
-- Strategy: Implementation of Non-Clustered Indexes on high-traffic 
-- Foreign Key and Temporal columns to prevent Full Table Scans.
-- ------------------------------------------------------------

-- Index on VOYAGE(departure_datetime) for faster voyage searches/filtering
CREATE NONCLUSTERED INDEX [IX_VOYAGE_Departure] 
ON [VOYAGE] ([departure_datetime]);
GO

-- Index on RESERVATION(voyage_id) for faster joins during manifest generation
CREATE NONCLUSTERED INDEX [IX_RES_VoyageID] 
ON [RESERVATION] ([voyage_id]);
GO

-- Index on RESERVATION_PASSENGER(reservation_id) for optimized billing/grouping
CREATE NONCLUSTERED INDEX [IX_RP_ResID] 
ON [RESERVATION_PASSENGER] ([reservation_id]);
GO

-- Index on PAYMENT(reservation_id) to accelerate financial reconciliation reports
CREATE NONCLUSTERED INDEX [IX_PAY_ResID] 
ON [PAYMENT] ([reservation_id]);
GO
