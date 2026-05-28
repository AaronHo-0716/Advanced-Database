-- ============================================================
-- 02_constraints.sql
-- Business rule validation for GLCL.
-- Brackets [] used for robustness.
-- ============================================================

-- Rule: Cabins have a maximum occupancy of 5.
ALTER TABLE [CABIN]
ADD CONSTRAINT [CHK_MAX_OCC] CHECK ([max_occupancy] <= 5);

-- Rule: Itinerary stops must be in order.
ALTER TABLE [ITINERARY_STOP]
ADD CONSTRAINT [CHK_STOP_SEQ] CHECK ([stop_order] > 0);

-- Rule: Voyage logical timing.
ALTER TABLE [VOYAGE]
ADD CONSTRAINT [CHK_VOYAGE_TIME] CHECK ([arrival_datetime] > [departure_datetime]);

-- Rule: Valid age range setup.
ALTER TABLE [AGE_CATEGORY]
ADD CONSTRAINT [CHK_AGE_BOUNDS] CHECK ([max_age] >= [min_age]);

-- Rule: Bedding type enum-like check.
ALTER TABLE [RESERVATION_PASSENGER]
ADD CONSTRAINT [CHK_BEDDING] CHECK ([bedding_type] IN ('Existing Bedding', 'Crib/Cot', 'Normal'));

-- Rule: Valid itinerary categories.
ALTER TABLE [VOYAGE]
ADD CONSTRAINT [CHK_ITIN_VAL] CHECK ([itinerary_type] IN ('One-way', 'Round-trip', 'Multi-destination'));

-- Rule: Financial non-negativity.
ALTER TABLE [VOYAGE_CABIN_FARE] ADD CONSTRAINT [CHK_ADULT_F] CHECK ([adult_fare] >= 0);
ALTER TABLE [RESCHEDULE] ADD CONSTRAINT [CHK_RESCH_F] CHECK ([reschedule_fee] >= 0);
ALTER TABLE [CANCELLATION] ADD CONSTRAINT [CHK_REFUND_V] CHECK ([refund_amount] >= 0);
GO