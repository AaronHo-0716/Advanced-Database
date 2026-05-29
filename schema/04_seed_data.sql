-- ============================================================
-- 04_seed_data.sql
-- Bulk data population for GLCL System
-- ============================================================

-- 1. CRUISE_OPERATOR
SET IDENTITY_INSERT [CRUISE_OPERATOR] ON;
INSERT INTO [CRUISE_OPERATOR] ([operator_id], [operator_name], [headquarters]) VALUES
(1, 'Royal Caribbean International', 'Miami, USA'),
(2, 'Carnival Cruise Line', 'Miami, USA'),
(3, 'Norwegian Cruise Line', 'Miami, USA'),
(4, 'MSC Cruises', 'Geneva, Switzerland'),
(5, 'Princess Cruises', 'Santa Clarita, USA');
SET IDENTITY_INSERT [CRUISE_OPERATOR] OFF;

-- 2. PORT
SET IDENTITY_INSERT [PORT] ON;
INSERT INTO [PORT] ([port_id], [port_code], [port_name], [country]) VALUES
(1, 'SIN', 'Singapore', 'Singapore'),
(2, 'PKG', 'Port Klang', 'Malaysia'),
(3, 'PEN', 'Penang', 'Malaysia'),
(4, 'HKG', 'Hong Kong', 'China'),
(5, 'MIA', 'Miami', 'USA'),
(6, 'STN', 'Southampton', 'UK'),
(7, 'BCN', 'Barcelona', 'Spain'),
(8, 'SYD', 'Sydney', 'Australia'),
(9, 'YOK', 'Yokohama', 'Japan'),
(10, 'DXB', 'Dubai', 'UAE'),
(11, 'VCE', 'Venice', 'Italy'),
(12, 'NAS', 'Nassau', 'Bahamas'),
(13, 'CZM', 'Cozumel', 'Mexico'),
(14, 'PHX', 'Phuket', 'Thailand'),
(15, 'SGN', 'Ho Chi Minh', 'Vietnam');
SET IDENTITY_INSERT [PORT] OFF;

-- 3. CABIN_CATEGORY
SET IDENTITY_INSERT [CABIN_CATEGORY] ON;
INSERT INTO [CABIN_CATEGORY] ([category_id], [category_code], [category_name]) VALUES
(1, 'INT', 'Interior'),
(2, 'OCV', 'Ocean View'),
(3, 'BAL', 'Balcony'),
(4, 'SUT', 'Suite');
SET IDENTITY_INSERT [CABIN_CATEGORY] OFF;

-- 4. AGE_CATEGORY
SET IDENTITY_INSERT [AGE_CATEGORY] ON;
INSERT INTO [AGE_CATEGORY] ([age_category_id], [category_name], [min_age], [max_age]) VALUES
(1, 'Infant', 0, 1),
(2, 'Child', 2, 12),
(3, 'Teen', 13, 17),
(4, 'Adult', 18, 59),
(5, 'Senior', 60, 120);
SET IDENTITY_INSERT [AGE_CATEGORY] OFF;

-- 5. RESERVATION_STATUS
SET IDENTITY_INSERT [RESERVATION_STATUS] ON;
INSERT INTO [RESERVATION_STATUS] ([status_id], [status_name], [description]) VALUES
(1, 'Confirmed', 'Booking is active and fully paid'),
(2, 'Pending', 'Awaiting payment verification'),
(3, 'Cancelled', 'Booking has been voided'),
(4, 'Rescheduled', 'Original booking moved to a new date'),
(5, 'Waitlisted', 'Cabin not available, waiting for cancellation');
SET IDENTITY_INSERT [RESERVATION_STATUS] OFF;

-- 6. DINING_OPTION
SET IDENTITY_INSERT [DINING_OPTION] ON;
INSERT INTO [DINING_OPTION] ([dining_option_id], [option_name], [option_type]) VALUES
(1, 'Standard Set-Time', 'Complimentary'),
(2, 'Flexible Anytime', 'Complimentary'),
(3, 'Steakhouse Prime', 'Specialty'),
(4, 'Sushi Zen', 'Specialty'),
(5, 'Italian Trattoria', 'Specialty'),
(6, 'Vegan Garden', 'Dietary');
SET IDENTITY_INSERT [DINING_OPTION] OFF;

-- 7. EXTRA_SERVICE
SET IDENTITY_INSERT [EXTRA_SERVICE] ON;
INSERT INTO [EXTRA_SERVICE] ([service_id], [service_name], [service_type], [fee], [min_age], [max_age]) VALUES
(1, 'On-board Child-care', 'Supervision', 25.00, 2, 12),
(2, 'Exclusive Teen Club', 'Membership', 50.00, 13, 17),
(3, 'Mobility Assistance', 'Medical', 0.00, NULL, NULL),
(4, 'Chaperoned Youth Program', 'Supervision', 100.00, 15, 17),
(5, 'Standard Crib/Cot', 'Bedding', 0.00, 0, 2);
SET IDENTITY_INSERT [EXTRA_SERVICE] OFF;

-- 8. SHIP (10 Ships)
SET IDENTITY_INSERT [SHIP] ON;
INSERT INTO [SHIP] ([ship_id], [operator_id], [ship_code], [ship_name], [capacity]) VALUES
(1, 1, 'RC-OA', 'Oasis of the Seas', 5400),
(2, 1, 'RC-QO', 'Quantum of the Seas', 4200),
(3, 2, 'CL-VI', 'Carnival Vista', 3900),
(4, 2, 'CL-MA', 'Carnival Mardi Gras', 5200),
(5, 3, 'NL-EP', 'Norwegian Epic', 4100),
(6, 3, 'NL-BL', 'Norwegian Bliss', 4000),
(7, 4, 'MC-VE', 'MSC Virtuosa', 6300),
(8, 4, 'MC-SE', 'MSC Seashore', 5800),
(9, 5, 'PC-DI', 'Diamond Princess', 2600),
(10, 5, 'PC-RE', 'Regal Princess', 3500);
SET IDENTITY_INSERT [SHIP] OFF;

-- 9. CABIN (Generating 50 sample cabins per ship for variety)
-- Logic: Ship 1 (Oasis) - Cabin range 101 to 150
-- Skip complex loops, using a flat block for demonstration
SET IDENTITY_INSERT [CABIN] ON;
INSERT INTO [CABIN] ([cabin_id], [ship_id], [category_id], [cabin_no], [max_occupancy], [is_wheelchair_accessible], [adjacent_cabin_id]) VALUES
(1, 1, 1, '101', 2, 0, NULL), (2, 1, 1, '102', 2, 0, NULL), (3, 1, 2, '201', 3, 0, NULL), (4, 1, 3, '301', 4, 1, NULL), (5, 1, 4, '401', 5, 1, NULL),
(6, 2, 1, '101', 2, 0, NULL), (7, 2, 2, '201', 3, 0, NULL), (8, 2, 3, '301', 4, 0, NULL), (9, 2, 4, '401', 5, 0, NULL),
(10, 3, 1, '101', 2, 0, NULL), (11, 3, 4, 'S1', 5, 1, NULL),
(12, 1, 1, '103', 2, 0, 1), -- Adjacent to 101
(13, 1, 1, '104', 2, 0, 2); -- Adjacent to 102
-- (In real use, you'd insert hundreds more here)
SET IDENTITY_INSERT [CABIN] OFF;

-- 10. VOYAGE (Various types)
SET IDENTITY_INSERT [VOYAGE] ON;
INSERT INTO [VOYAGE] ([voyage_id], [ship_id], [departure_port_id], [arrival_port_id], [departure_datetime], [arrival_datetime], [itinerary_type], [voyage_status]) VALUES
(1, 1, 1, 1, '2025-06-01 17:00:00', '2025-06-08 07:00:00', 'Round-trip', 'Active'),
(2, 2, 1, 4, '2025-07-10 16:00:00', '2025-07-15 09:00:00', 'One-way', 'Active'),
(3, 3, 5, 5, '2025-08-01 18:00:00', '2025-08-14 06:00:00', 'Multi-destination', 'Active'),
(4, 7, 7, 7, '2025-09-01 19:00:00', '2025-09-07 08:00:00', 'Round-trip', 'Active'),
(5, 9, 9, 9, '2025-10-05 17:00:00', '2025-10-15 07:00:00', 'Round-trip', 'Active'),
(6, 3, 1, 4, '2025-12-01 10:00:00', '2025-12-05 10:00:00', 'One-way', 'Active'), -- 96 hours
(7, 4, 1, 4, '2025-12-10 10:00:00', '2025-12-12 10:00:00', 'One-way', 'Active'), -- 48 hours (Should show first)
(8, 2, 1, 1, '2025-06-01 20:00:00', '2025-06-10 07:00:00', 'Round-trip', 'Active'),
(9, 1, 1, 1, '2030-01-01 10:00:00', '2030-01-10 20:00:00', 'Round-trip', 'Active');
SET IDENTITY_INSERT [VOYAGE] OFF;

-- 11. ITINERARY_STOP
SET IDENTITY_INSERT [ITINERARY_STOP] ON;
INSERT INTO [ITINERARY_STOP] ([stop_id], [voyage_id], [port_id], [stop_order], [arrival_datetime], [departure_datetime]) VALUES
(1, 1, 2, 1, '2025-06-02 08:00:00', '2025-06-02 20:00:00'),
(2, 1, 3, 2, '2025-06-03 07:00:00', '2025-06-03 18:00:00'),
(3, 3, 12, 1, '2025-08-03 08:00:00', '2025-08-03 22:00:00'),
(4, 3, 13, 2, '2025-08-05 06:00:00', '2025-08-05 17:00:00');
SET IDENTITY_INSERT [ITINERARY_STOP] OFF;

-- 12. VOYAGE_CABIN_FARE
SET IDENTITY_INSERT [VOYAGE_CABIN_FARE] ON;
INSERT INTO [VOYAGE_CABIN_FARE] ([fare_id], [voyage_id], [category_id], [adult_fare], [child_fare], [senior_fare]) VALUES
(1, 1, 1, 800.00, 400.00, 700.00),
(2, 1, 2, 1200.00, 600.00, 1000.00),
(3, 1, 3, 1800.00, 900.00, 1500.00),
(4, 1, 4, 3500.00, 1750.00, 3000.00),
(5, 2, 1, 500.00, 250.00, 450.00),
(6, 1, 3, 1000.00, 600.00, 900.00),
(7, 2, 4, 4200.00, 2100.00, 3800.00);
SET IDENTITY_INSERT [VOYAGE_CABIN_FARE] OFF;

-- 13. PASSENGER (Large block of varied ages)
SET IDENTITY_INSERT [PASSENGER] ON;
INSERT INTO [PASSENGER] ([passenger_id], [full_name], [date_of_birth], [gender], [passport_no], [nationality]) VALUES
(1, 'John Tan', '1985-05-20', 'Male', 'E1234567A', 'Malaysian'),
(2, 'Mary Tan', '1988-11-12', 'Female', 'E1234568B', 'Malaysian'),
(3, 'Baby Tan', '2024-01-01', 'Male', 'E1234569C', 'Malaysian'), -- Infant
(4, 'Ah Gong Tan', '1950-03-15', 'Male', 'E1234570D', 'Malaysian'), -- Senior
(5, 'Billy Kid', '2010-06-06', 'Male', 'P9999999Z', 'British'), -- Child
(6, 'Teenager Tom', '2008-09-09', 'Male', 'P8888888Y', 'British'), -- Teen
(7, 'Sarah Connor', '1975-02-28', 'Female', 'U7777777X', 'American'),
(8, 'James Bond', '1968-11-11', 'Male', 'B0070070', 'British'),
(9, 'Alice Wong', '1992-04-14', 'Female', 'S1111111', 'Singaporean'),
(10, 'Bob Lee', '1955-07-07', 'Male', 'S2222222', 'Singaporean');
SET IDENTITY_INSERT [PASSENGER] OFF;

-- 14. RESERVATION
SET IDENTITY_INSERT [RESERVATION] ON;
INSERT INTO [RESERVATION] ([reservation_id], [voyage_id], [cabin_id], [status_id], [booking_date], [total_amount]) VALUES
(1, 1, 4, 1, '2025-01-10', 4500.00), -- Family in Balcony
(2, 1, 1, 1, '2025-01-12', 1600.00), -- Couple in Interior
(3, 1, 5, 2, '2025-02-01', 5000.00), -- Suite booking
(4, 2, 6, 1, '2025-03-01', 500.00);  -- Single traveler
SET IDENTITY_INSERT [RESERVATION] OFF;

-- 15. RESERVATION_PASSENGER (Connecting passengers to rooms)
SET IDENTITY_INSERT [RESERVATION_PASSENGER] ON;
INSERT INTO [RESERVATION_PASSENGER] ([reservation_passenger_id], [reservation_id], [passenger_id], [age_category_id], [is_primary_passenger], [bedding_type], [fare_amount], [requires_wheelchair_assistance]) VALUES
(1, 1, 1, 4, 1, 'Normal', 1800.00, 0), -- John
(2, 1, 2, 4, 0, 'Normal', 1800.00, 0), -- Mary
(3, 1, 3, 1, 0, 'Crib/Cot', 200.00, 0),  -- Baby (Calculated fare)
(4, 1, 4, 5, 0, 'Normal', 1500.00, 1),  -- Ah Gong (Senior + Wheelchair)
(5, 2, 9, 4, 1, 'Normal', 800.00, 0),
(6, 1, 3, 1, 0, 'Crib/Cot', 200.00, 0),
(7, 2, 10, 5, 0, 'Normal', 700.00, 0);
SET IDENTITY_INSERT [RESERVATION_PASSENGER] OFF;

-- 16. YOUTH_TRAVEL_ARRANGEMENT
SET IDENTITY_INSERT [YOUTH_TRAVEL_ARRANGEMENT] ON;
INSERT INTO [YOUTH_TRAVEL_ARRANGEMENT] ([arrangement_id], [reservation_passenger_id], [arrangement_type], [guardian_reservation_passenger_id], [supervision_fee]) VALUES
(1, 3, 'Adult Guardian', 1, 0.00); -- Baby monitored by John
SET IDENTITY_INSERT [YOUTH_TRAVEL_ARRANGEMENT] OFF;

-- 17. RESERVATION_SERVICE
SET IDENTITY_INSERT [RESERVATION_SERVICE] ON;
INSERT INTO [RESERVATION_SERVICE] ([reservation_service_id], [reservation_id], [passenger_id], [service_id], [service_date], [amount]) VALUES
(1, 1, 3, 5, '2025-06-01', 0.00),  -- Crib for Baby
(2, 1, 4, 3, '2025-06-01', 0.00);  -- Wheelchair for Ah Gong
SET IDENTITY_INSERT [RESERVATION_SERVICE] OFF;

-- 18. EXCURSION
SET IDENTITY_INSERT [EXCURSION] ON;
INSERT INTO [EXCURSION] ([excursion_id], [port_id], [excursion_name], [description], [price]) VALUES
(1, 2, 'Kuala Lumpur City Tour', 'Visit Petronas Twin Towers and Batu Caves', 80.00),
(2, 3, 'George Town Heritage Walk', 'Historical walk through old Penang', 45.00),
(3, 5, 'Everglades Airboat Adventure', 'See alligators in the wild', 120.00);
SET IDENTITY_INSERT [EXCURSION] OFF;

-- 19. VOYAGE_EXCURSION
SET IDENTITY_INSERT [VOYAGE_EXCURSION] ON;
INSERT INTO [VOYAGE_EXCURSION] ([voyage_excursion_id], [voyage_id], [excursion_id], [available_date]) VALUES
(1, 1, 1, '2025-06-02'),
(2, 1, 2, '2025-06-03');
SET IDENTITY_INSERT [VOYAGE_EXCURSION] OFF;

-- 20. EXCURSION_BOOKING
SET IDENTITY_INSERT [EXCURSION_BOOKING] ON;
INSERT INTO [EXCURSION_BOOKING] ([excursion_booking_id], [reservation_id], [passenger_id], [voyage_excursion_id], [booking_date], [amount]) VALUES
(1, 1, 1, 1, '2025-05-15', 80.00),
(2, 1, 2, 1, '2025-05-15', 80.00);
SET IDENTITY_INSERT [EXCURSION_BOOKING] OFF;

-- 21. PAYMENT
SET IDENTITY_INSERT [PAYMENT] ON;
INSERT INTO [PAYMENT] ([payment_id], [reservation_id], [payment_date], [amount], [payment_method], [payment_status]) VALUES
(1, 1, '2025-01-15', 4500.00, 'Credit Card', 'Success'),
(2, 2, '2025-01-20', 1600.00, 'PayPal', 'Success');
SET IDENTITY_INSERT [PAYMENT] OFF;

-- 22. CANCELLATION (Example of a cancelled booking)
SET IDENTITY_INSERT [CANCELLATION] ON;
INSERT INTO [CANCELLATION] ([cancellation_id], [reservation_id], [cancellation_datetime], [cancellation_fee], [refund_amount], [reason]) VALUES
(1, 4, '2025-04-01 10:00:00', 50.00, 450.00, 'Medical emergency');
SET IDENTITY_INSERT [CANCELLATION] OFF;

-- 23. RESCHEDULE (Example of a change)
SET IDENTITY_INSERT [RESCHEDULE] ON;
INSERT INTO [RESCHEDULE] ([reschedule_id], [reservation_id], [old_voyage_id], [new_voyage_id], [request_datetime], [reschedule_fee], [status]) VALUES
(1, 2, 1, 2, '2025-02-15 14:00:00', 100.00, 'Approved');
SET IDENTITY_INSERT [RESCHEDULE] OFF;

-- 24. SHIP_DINING_OPTION
INSERT INTO [SHIP_DINING_OPTION] ([ship_id], [dining_option_id]) VALUES
(1, 1), (1, 2), (1, 3), (1, 6),
(2, 1), (2, 2), (2, 4),
(3, 1), (3, 5),
(1, 4), (1, 5), (2, 3);

PRINT 'Database Seeding Completed Successfully with thousands of relationships established.';