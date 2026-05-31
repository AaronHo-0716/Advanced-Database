-- ============================================================
-- 03c_member3_objects.sql
-- OWNER: Member 3
-- Apply order: 3rd (any of 03a/03b/03c order is fine; they are
-- independent by design).
-- Engine: MS SQL Server (T-SQL).
-- ------------------------------------------------------------
-- Contents required by the assignment (one of each):
--   1. One CHECK constraint (or table-level constraint)
--   2. One trigger
--   3. One stored procedure or user-defined function
-- Keep all three in this file so ownership stays conflict-free.
-- ============================================================

-- TODO: Member 3 to author constraint here.

-- TODO: Member 3 to author trigger here.
CREATE TRIGGER [TRG_TEEN_TRAVEL_VALIDATION]
ON [YOUTH_TRAVEL_ARRANGEMENT]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Arrangement type must be one of the accepted youth policy options.
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.arrangement_type NOT IN ('Adult Guardian', 'Chaperoned Youth Program')
    )
    BEGIN
        RAISERROR (
            'Invalid youth travel arrangement type.',
            16,
            1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Youth arrangement should only be created for passengers below 18.
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN [RESERVATION_PASSENGER] teen_rp
            ON i.reservation_passenger_id = teen_rp.reservation_passenger_id
        INNER JOIN [PASSENGER] teen_p
            ON teen_rp.passenger_id = teen_p.passenger_id
        WHERE DATEADD(YEAR, 18, teen_p.date_of_birth) <= CAST(GETDATE() AS DATE)
    )
    BEGIN
        RAISERROR (
            'Youth travel arrangement can only be created for passengers below 18.',
            16,
            1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Chaperoned Youth Program is only valid for teens aged 15 to 17.
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN [RESERVATION_PASSENGER] teen_rp
            ON i.reservation_passenger_id = teen_rp.reservation_passenger_id
        INNER JOIN [PASSENGER] teen_p
            ON teen_rp.passenger_id = teen_p.passenger_id
        WHERE i.arrangement_type = 'Chaperoned Youth Program'
          AND (
                DATEADD(YEAR, 15, teen_p.date_of_birth) > CAST(GETDATE() AS DATE)
                OR DATEADD(YEAR, 18, teen_p.date_of_birth) <= CAST(GETDATE() AS DATE)
              )
    )
    BEGIN
        RAISERROR (
            'Chaperoned Youth Program is only valid for passengers aged 15 to 17.',
            16,
            1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Adult Guardian arrangement must point to a valid adult guardian.
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.arrangement_type = 'Adult Guardian'
          AND i.guardian_reservation_passenger_id IS NULL
    )
    BEGIN
        RAISERROR (
            'Adult Guardian arrangement requires a guardian reservation passenger ID.',
            16,
            1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Chaperoned Youth Program should not have a guardian ID.
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.arrangement_type = 'Chaperoned Youth Program'
          AND i.guardian_reservation_passenger_id IS NOT NULL
    )
    BEGIN
        RAISERROR (
            'Chaperoned Youth Program arrangement should not reference an adult guardian.',
            16,
            1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Validate adult guardian: adult, same voyage, same or adjacent cabin.
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN [RESERVATION_PASSENGER] teen_rp
            ON i.reservation_passenger_id = teen_rp.reservation_passenger_id
        INNER JOIN [RESERVATION] teen_r
            ON teen_rp.reservation_id = teen_r.reservation_id
        INNER JOIN [CABIN] teen_c
            ON teen_r.cabin_id = teen_c.cabin_id
        INNER JOIN [RESERVATION_PASSENGER] guardian_rp
            ON i.guardian_reservation_passenger_id = guardian_rp.reservation_passenger_id
        INNER JOIN [PASSENGER] guardian_p
            ON guardian_rp.passenger_id = guardian_p.passenger_id
        INNER JOIN [RESERVATION] guardian_r
            ON guardian_rp.reservation_id = guardian_r.reservation_id
        INNER JOIN [CABIN] guardian_c
            ON guardian_r.cabin_id = guardian_c.cabin_id
        WHERE i.arrangement_type = 'Adult Guardian'
          AND (
                DATEADD(YEAR, 18, guardian_p.date_of_birth) > CAST(GETDATE() AS DATE)
                OR guardian_r.voyage_id <> teen_r.voyage_id
                OR NOT (
                    guardian_c.cabin_id = teen_c.cabin_id
                    OR guardian_c.cabin_id = teen_c.adjacent_cabin_id
                    OR teen_c.cabin_id = guardian_c.adjacent_cabin_id
                )
              )
    )
    BEGIN
        RAISERROR (
            'Invalid adult guardian arrangement. Guardian must be at least 18 and booked in the same or adjacent cabin on the same voyage.',
            16,
            1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

-- TODO: Member 3 to author stored procedure / function here.
CREATE OR ALTER FUNCTION dbo.fn_CalculateChaperonedYouthFee
(
    @ReservationPassengerID INT
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @TotalSupervisionFee DECIMAL(18, 2) = 0.00;
    DECLARE @DailyFee DECIMAL(18, 2) = 0.00;
    DECLARE @VoyageDurationDays INT = 0;
    DECLARE @ArrangementType VARCHAR(50);
    DECLARE @DepartureDateTime DATETIME;
    DECLARE @ArrivalDateTime DATETIME;

    SELECT @ArrangementType = arrangement_type
    FROM [YOUTH_TRAVEL_ARRANGEMENT]
    WHERE reservation_passenger_id = @ReservationPassengerID;

    IF @ArrangementType IS NULL OR @ArrangementType <> 'Chaperoned Youth Program'
    BEGIN
        RETURN 0.00;
    END;

    SELECT @DailyFee = fee
    FROM [EXTRA_SERVICE]
    WHERE service_name = 'Chaperoned Youth Program';

    SELECT
        @DepartureDateTime = v.departure_datetime,
        @ArrivalDateTime = v.arrival_datetime
    FROM [RESERVATION_PASSENGER] rp
    INNER JOIN [RESERVATION] r
        ON rp.reservation_id = r.reservation_id
    INNER JOIN [VOYAGE] v
        ON r.voyage_id = v.voyage_id
    WHERE rp.reservation_passenger_id = @ReservationPassengerID;

    SET @VoyageDurationDays =
        CEILING(DATEDIFF(MINUTE, @DepartureDateTime, @ArrivalDateTime) / 1440.0);

    IF @VoyageDurationDays <= 0
    BEGIN
        SET @VoyageDurationDays = 1;
    END;

    SET @TotalSupervisionFee = @DailyFee * @VoyageDurationDays;

    RETURN @TotalSupervisionFee;
END;
GO
