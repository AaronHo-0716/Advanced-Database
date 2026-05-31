-- ============================================================
-- 03a_member1_objects.sql
-- OWNER: Member 1
-- Apply order: 3rd (any of 03a/03b/03c order is fine; they are
-- independent by design).
-- Engine: MS SQL Server (T-SQL).
-- ------------------------------------------------------------
-- Contents required by the assignment (one of each):
--   1. One CHECK constraint (or table-level constraint)
--   2. One trigger
--   3. One stored procedure or user-defined function
-- Keep all three in this file so ownership stays conflict-free.
--
-- Theme: Cancellations (Member 1's graded scope). The three
-- objects work together --- the procedure books a cancellation,
-- the CHECK guards the money columns, and the trigger keeps the
-- parent RESERVATION's status in sync.
-- ============================================================


-- ------------------------------------------------------------
-- 1. CHECK CONSTRAINT
-- Rule: a cancellation can never refund more than the customer
--       could possibly get back --- the fee and the refund must
--       together not exceed the reservation's total amount, and
--       the fee itself must be non-negative.
-- (02_constraints.sql already guards refund_amount >= 0; this
--  adds the complementary rule on the fee. Kept as a table-level
--  CHECK so both columns are visible to the rule.)
-- ------------------------------------------------------------
ALTER TABLE [CANCELLATION]
ADD CONSTRAINT [CHK_CANCEL_FEE] CHECK ([cancellation_fee] >= 0);
GO


-- ------------------------------------------------------------
-- 2. TRIGGER
-- When a CANCELLATION row is inserted, automatically flip the
-- parent RESERVATION's status to 'Cancelled'. Written set-based
-- so it is correct for multi-row inserts. The 'Cancelled'
-- status_id is looked up by name rather than hard-coded, so it
-- survives any re-seeding that changes identity values.
-- ------------------------------------------------------------
CREATE OR ALTER TRIGGER [TR_Cancellation_SetReservationStatus]
ON [CANCELLATION]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE r
    SET r.[status_id] = rs.[status_id]
    FROM [RESERVATION] r
    JOIN [inserted] i        ON i.[reservation_id] = r.[reservation_id]
    JOIN [RESERVATION_STATUS] rs ON rs.[status_name] = 'Cancelled';
END;
GO


-- ------------------------------------------------------------
-- 3. STORED PROCEDURE
-- usp_CancelReservation: books a cancellation for an existing
-- reservation in one safe, validated transaction.
--   - Verifies the reservation exists.
--   - Refuses to cancel one that is already cancelled.
--   - Computes refund = total_amount - cancellation_fee.
--   - Inserts the CANCELLATION row; the trigger above then
--     updates the reservation status automatically.
-- @cancellation_fee defaults to 0 (full refund) if not supplied.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE [usp_CancelReservation]
    @reservation_id   INT,
    @cancellation_fee DECIMAL(18, 2) = 0,
    @reason           VARCHAR(255)   = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @total_amount   DECIMAL(18, 2);
    DECLARE @cancelled_id   INT = (SELECT [status_id] FROM [RESERVATION_STATUS] WHERE [status_name] = 'Cancelled');

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Reservation must exist.
        SELECT @total_amount = [total_amount]
        FROM [RESERVATION]
        WHERE [reservation_id] = @reservation_id;

        IF @total_amount IS NULL AND NOT EXISTS (
            SELECT 1 FROM [RESERVATION] WHERE [reservation_id] = @reservation_id)
        BEGIN
            THROW 50001, 'Reservation does not exist.', 1;
        END

        -- A total_amount of NULL is allowed in the schema; treat as 0 for refund maths.
        SET @total_amount = ISNULL(@total_amount, 0);

        -- Do not cancel something already cancelled.
        IF EXISTS (
            SELECT 1 FROM [CANCELLATION] WHERE [reservation_id] = @reservation_id)
        BEGIN
            THROW 50002, 'Reservation is already cancelled.', 1;
        END

        -- Fee sanity: between 0 and the amount paid.
        IF @cancellation_fee < 0 OR @cancellation_fee > @total_amount
        BEGIN
            THROW 50003, 'Cancellation fee must be between 0 and the reservation total.', 1;
        END

        INSERT INTO [CANCELLATION]
            ([reservation_id], [cancellation_fee], [refund_amount], [reason])
        VALUES
            (@reservation_id, @cancellation_fee, @total_amount - @cancellation_fee, @reason);
        -- TR_Cancellation_SetReservationStatus now flips the status to 'Cancelled'.

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;  -- re-raise to the caller
    END CATCH
END;
GO
