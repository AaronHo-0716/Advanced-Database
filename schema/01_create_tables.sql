-- ============================================================
-- 01_create_tables.sql
-- GLCL schema — table definitions (24 tables), PKs, FKs.
-- Engine: MS SQL Server (T-SQL).
-- Brackets [] used to prevent space-stripping errors.
-- ============================================================

-- 1. CRUISE_OPERATOR
CREATE TABLE [CRUISE_OPERATOR] (
    [operator_id] INT IDENTITY(1,1) PRIMARY KEY,
    [operator_name] VARCHAR(100) NOT NULL,
    [headquarters] VARCHAR(100)
);
GO

-- 2. PORT
CREATE TABLE [PORT] (
    [port_id] INT IDENTITY(1,1) PRIMARY KEY,
    [port_code] VARCHAR(10) NOT NULL UNIQUE,
    [port_name] VARCHAR(100) NOT NULL,
    [country] VARCHAR(100) NOT NULL
);
GO

-- 3. SHIP
CREATE TABLE [SHIP] (
    [ship_id] INT IDENTITY(1,1) PRIMARY KEY,
    [operator_id] INT NOT NULL,
    [ship_code] VARCHAR(20) NOT NULL UNIQUE,
    [ship_name] VARCHAR(100) NOT NULL,
    [capacity] INT NOT NULL,
    CONSTRAINT [FK_SHIP_OPERATOR] FOREIGN KEY ([operator_id]) REFERENCES [CRUISE_OPERATOR]([operator_id])
);
GO

-- 4. CABIN_CATEGORY
CREATE TABLE [CABIN_CATEGORY] (
    [category_id] INT IDENTITY(1,1) PRIMARY KEY,
    [category_code] VARCHAR(10) NOT NULL UNIQUE,
    [category_name] VARCHAR(50) NOT NULL
);
GO

-- 5. CABIN
CREATE TABLE [CABIN] (
    [cabin_id] INT IDENTITY(1,1) PRIMARY KEY,
    [ship_id] INT NOT NULL,
    [category_id] INT NOT NULL,
    [cabin_no] VARCHAR(10) NOT NULL,
    [max_occupancy] INT NOT NULL,
    [is_wheelchair_accessible] BIT DEFAULT 0,
    [adjacent_cabin_id] INT NULL,
    CONSTRAINT [FK_CABIN_SHIP] FOREIGN KEY ([ship_id]) REFERENCES [SHIP]([ship_id]),
    CONSTRAINT [FK_CABIN_CATEGORY] FOREIGN KEY ([category_id]) REFERENCES [CABIN_CATEGORY]([category_id]),
    CONSTRAINT [FK_CABIN_ADJACENT] FOREIGN KEY ([adjacent_cabin_id]) REFERENCES [CABIN]([cabin_id])
);
GO

-- 6. VOYAGE
CREATE TABLE [VOYAGE] (
    [voyage_id] INT IDENTITY(1,1) PRIMARY KEY,
    [ship_id] INT NOT NULL,
    [departure_port_id] INT NOT NULL,
    [arrival_port_id] INT NOT NULL,
    [departure_datetime] DATETIME NOT NULL,
    [arrival_datetime] DATETIME NOT NULL,
    [itinerary_type] VARCHAR(50) NOT NULL,
    [voyage_status] VARCHAR(20) NOT NULL,
    -- Computed column based on sailing length (Business Rule)
    [meal_package] AS (CASE 
        WHEN DATEDIFF(HOUR, [departure_datetime], [arrival_datetime]) > 24 THEN 'All-Inclusive' 
        ELSE 'Standard Boarding' 
    END),
    CONSTRAINT [FK_VOYAGE_SHIP] FOREIGN KEY ([ship_id]) REFERENCES [SHIP]([ship_id]),
    CONSTRAINT [FK_VOYAGE_DEP_PORT] FOREIGN KEY ([departure_port_id]) REFERENCES [PORT]([port_id]),
    CONSTRAINT [FK_VOYAGE_ARR_PORT] FOREIGN KEY ([arrival_port_id]) REFERENCES [PORT]([port_id])
);
GO

-- 7. ITINERARY_STOP
CREATE TABLE [ITINERARY_STOP] (
    [stop_id] INT IDENTITY(1,1) PRIMARY KEY,
    [voyage_id] INT NOT NULL,
    [port_id] INT NOT NULL,
    [stop_order] INT NOT NULL,
    [arrival_datetime] DATETIME,
    [departure_datetime] DATETIME,
    CONSTRAINT [FK_STOP_VOYAGE] FOREIGN KEY ([voyage_id]) REFERENCES [VOYAGE]([voyage_id]),
    CONSTRAINT [FK_STOP_PORT] FOREIGN KEY ([port_id]) REFERENCES [PORT]([port_id])
);
GO

-- 8. VOYAGE_CABIN_FARE
CREATE TABLE [VOYAGE_CABIN_FARE] (
    [fare_id] INT IDENTITY(1,1) PRIMARY KEY,
    [voyage_id] INT NOT NULL,
    [category_id] INT NOT NULL,
    [adult_fare] DECIMAL(18, 2) NOT NULL,
    [child_fare] DECIMAL(18, 2) NOT NULL,
    [senior_fare] DECIMAL(18, 2) NOT NULL,
    CONSTRAINT [FK_FARE_VOYAGE] FOREIGN KEY ([voyage_id]) REFERENCES [VOYAGE]([voyage_id]),
    CONSTRAINT [FK_FARE_CAT] FOREIGN KEY ([category_id]) REFERENCES [CABIN_CATEGORY]([category_id])
);
GO

-- 9. PASSENGER
CREATE TABLE [PASSENGER] (
    [passenger_id] INT IDENTITY(1,1) PRIMARY KEY,
    [full_name] VARCHAR(150) NOT NULL,
    [date_of_birth] DATE NOT NULL,
    [gender] VARCHAR(20),
    [passport_no] VARCHAR(50) UNIQUE NOT NULL,
    [nationality] VARCHAR(100) NOT NULL
);
GO

-- 10. AGE_CATEGORY
CREATE TABLE [AGE_CATEGORY] (
    [age_category_id] INT IDENTITY(1,1) PRIMARY KEY,
    [category_name] VARCHAR(50) NOT NULL,
    [min_age] INT NOT NULL,
    [max_age] INT NOT NULL
);
GO

-- 11. RESERVATION_STATUS
CREATE TABLE [RESERVATION_STATUS] (
    [status_id] INT IDENTITY(1,1) PRIMARY KEY,
    [status_name] VARCHAR(50) NOT NULL UNIQUE,
    [description] VARCHAR(255)
);
GO

-- 12. RESERVATION
CREATE TABLE [RESERVATION] (
    [reservation_id] INT IDENTITY(1,1) PRIMARY KEY,
    [voyage_id] INT NOT NULL,
    [cabin_id] INT NOT NULL,
    [status_id] INT NOT NULL,
    [booking_date] DATETIME NOT NULL DEFAULT GETDATE(),
    [total_amount] DECIMAL(18, 2),
    CONSTRAINT [FK_RES_VOYAGE] FOREIGN KEY ([voyage_id]) REFERENCES [VOYAGE]([voyage_id]),
    CONSTRAINT [FK_RES_CABIN] FOREIGN KEY ([cabin_id]) REFERENCES [CABIN]([cabin_id]),
    CONSTRAINT [FK_RES_STATUS] FOREIGN KEY ([status_id]) REFERENCES [RESERVATION_STATUS]([status_id])
);
GO

-- 13. RESERVATION_PASSENGER
CREATE TABLE [RESERVATION_PASSENGER] (
    [reservation_passenger_id] INT IDENTITY(1,1) PRIMARY KEY,
    [reservation_id] INT NOT NULL,
    [passenger_id] INT NOT NULL,
    [age_category_id] INT NOT NULL,
    [is_primary_passenger] BIT NOT NULL DEFAULT 0,
    [bedding_type] VARCHAR(50) NOT NULL,
    [fare_amount] DECIMAL(18, 2),
    [requires_wheelchair_assistance] BIT DEFAULT 0,
    CONSTRAINT [FK_REGPASS_RES] FOREIGN KEY ([reservation_id]) REFERENCES [RESERVATION]([reservation_id]),
    CONSTRAINT [FK_REGPASS_PASS] FOREIGN KEY ([passenger_id]) REFERENCES [PASSENGER]([passenger_id]),
    CONSTRAINT [FK_REGPASS_AGE] FOREIGN KEY ([age_category_id]) REFERENCES [AGE_CATEGORY]([age_category_id])
);
GO

-- 14. YOUTH_TRAVEL_ARRANGEMENT
CREATE TABLE [YOUTH_TRAVEL_ARRANGEMENT] (
    [arrangement_id] INT IDENTITY(1,1) PRIMARY KEY,
    [reservation_passenger_id] INT NOT NULL,
    [arrangement_type] VARCHAR(50),
    [guardian_reservation_passenger_id] INT NULL,
    [supervision_fee] DECIMAL(18, 2) DEFAULT 0,
    CONSTRAINT [FK_YOUTH_PASSENGER] FOREIGN KEY ([reservation_passenger_id]) REFERENCES [RESERVATION_PASSENGER]([reservation_passenger_id]),
    CONSTRAINT [FK_YOUTH_GUARDIAN] FOREIGN KEY ([guardian_reservation_passenger_id]) REFERENCES [RESERVATION_PASSENGER]([reservation_passenger_id])
);
GO

-- 15. DINING_OPTION
CREATE TABLE [DINING_OPTION] (
    [dining_option_id] INT IDENTITY(1,1) PRIMARY KEY,
    [option_name] VARCHAR(100) NOT NULL,
    [option_type] VARCHAR(50) NOT NULL
);
GO

-- 16. SHIP_DINING_OPTION
CREATE TABLE [SHIP_DINING_OPTION] (
    [ship_id] INT NOT NULL,
    [dining_option_id] INT NOT NULL,
    CONSTRAINT [PK_SHIP_DINING] PRIMARY KEY ([ship_id], [dining_option_id]),
    CONSTRAINT [FK_SDO_SHIP] FOREIGN KEY ([ship_id]) REFERENCES [SHIP]([ship_id]),
    CONSTRAINT [FK_SDO_DINING] FOREIGN KEY ([dining_option_id]) REFERENCES [DINING_OPTION]([dining_option_id])
);
GO

-- 17. EXTRA_SERVICE
CREATE TABLE [EXTRA_SERVICE] (
    [service_id] INT IDENTITY(1,1) PRIMARY KEY,
    [service_name] VARCHAR(100) NOT NULL,
    [service_type] VARCHAR(50),
    [fee] DECIMAL(18, 2) NOT NULL,
    [min_age] INT,
    [max_age] INT
);
GO

-- 18. RESERVATION_SERVICE
CREATE TABLE [RESERVATION_SERVICE] (
    [reservation_service_id] INT IDENTITY(1,1) PRIMARY KEY,
    [reservation_id] INT NOT NULL,
    [passenger_id] INT NOT NULL,
    [service_id] INT NOT NULL,
    [service_date] DATE,
    [amount] DECIMAL(18, 2),
    CONSTRAINT [FK_RESSERV_RES] FOREIGN KEY ([reservation_id]) REFERENCES [RESERVATION]([reservation_id]),
    CONSTRAINT [FK_RESSERV_PASS] FOREIGN KEY ([passenger_id]) REFERENCES [PASSENGER]([passenger_id]),
    CONSTRAINT [FK_RESSERV_SERV] FOREIGN KEY ([service_id]) REFERENCES [EXTRA_SERVICE]([service_id])
);
GO

-- 19. EXCURSION
CREATE TABLE [EXCURSION] (
    [excursion_id] INT IDENTITY(1,1) PRIMARY KEY,
    [port_id] INT NOT NULL,
    [excursion_name] VARCHAR(150) NOT NULL,
    [description] TEXT,
    [price] DECIMAL(18, 2) NOT NULL,
    CONSTRAINT [FK_EXC_PORT] FOREIGN KEY ([port_id]) REFERENCES [PORT]([port_id])
);
GO

-- 20. VOYAGE_EXCURSION
CREATE TABLE [VOYAGE_EXCURSION] (
    [voyage_excursion_id] INT IDENTITY(1,1) PRIMARY KEY,
    [voyage_id] INT NOT NULL,
    [excursion_id] INT NOT NULL,
    [available_date] DATE NOT NULL,
    CONSTRAINT [FK_VOYEX_VOYAGE] FOREIGN KEY ([voyage_id]) REFERENCES [VOYAGE]([voyage_id]),
    CONSTRAINT [FK_VOYEX_EXC] FOREIGN KEY ([excursion_id]) REFERENCES [EXCURSION]([excursion_id])
);
GO

-- 21. EXCURSION_BOOKING
CREATE TABLE [EXCURSION_BOOKING] (
    [excursion_booking_id] INT IDENTITY(1,1) PRIMARY KEY,
    [reservation_id] INT NOT NULL,
    [passenger_id] INT NOT NULL,
    [voyage_excursion_id] INT NOT NULL,
    [booking_date] DATETIME DEFAULT GETDATE(),
    [amount] DECIMAL(18, 2),
    CONSTRAINT [FK_EXCBK_RES] FOREIGN KEY ([reservation_id]) REFERENCES [RESERVATION]([reservation_id]),
    CONSTRAINT [FK_EXCBK_PASS] FOREIGN KEY ([passenger_id]) REFERENCES [PASSENGER]([passenger_id]),
    CONSTRAINT [FK_EXCBK_VOYEX] FOREIGN KEY ([voyage_excursion_id]) REFERENCES [VOYAGE_EXCURSION]([voyage_excursion_id])
);
GO

-- 22. CANCELLATION
CREATE TABLE [CANCELLATION] (
    [cancellation_id] INT IDENTITY(1,1) PRIMARY KEY,
    [reservation_id] INT NOT NULL,
    [cancellation_datetime] DATETIME NOT NULL DEFAULT GETDATE(),
    [cancellation_fee] DECIMAL(18, 2) NOT NULL,
    [refund_amount] DECIMAL(18, 2) NOT NULL,
    [reason] VARCHAR(255),
    CONSTRAINT [FK_CANCEL_RES] FOREIGN KEY ([reservation_id]) REFERENCES [RESERVATION]([reservation_id])
);
GO

-- 23. RESCHEDULE
CREATE TABLE [RESCHEDULE] (
    [reschedule_id] INT IDENTITY(1,1) PRIMARY KEY,
    [reservation_id] INT NOT NULL,
    [old_voyage_id] INT NOT NULL,
    [new_voyage_id] INT NOT NULL,
    [request_datetime] DATETIME NOT NULL DEFAULT GETDATE(),
    [reschedule_fee] DECIMAL(18, 2),
    [status] VARCHAR(20),
    CONSTRAINT [FK_RESCH_RES] FOREIGN KEY ([reservation_id]) REFERENCES [RESERVATION]([reservation_id]),
    CONSTRAINT [FK_RESCH_OLD] FOREIGN KEY ([old_voyage_id]) REFERENCES [VOYAGE]([voyage_id]),
    CONSTRAINT [FK_RESCH_NEW] FOREIGN KEY ([new_voyage_id]) REFERENCES [VOYAGE]([voyage_id])
);
GO

-- 24. PAYMENT
CREATE TABLE [PAYMENT] (
    [payment_id] INT IDENTITY(1,1) PRIMARY KEY,
    [reservation_id] INT NOT NULL,
    [payment_date] DATETIME NOT NULL DEFAULT GETDATE(),
    [amount] DECIMAL(18, 2) NOT NULL,
    [payment_method] VARCHAR(50),
    [payment_status] VARCHAR(20),
    CONSTRAINT [FK_PAY_RES] FOREIGN KEY ([reservation_id]) REFERENCES [RESERVATION]([reservation_id])
);
GO

-- Create Indexes for performance optimization
CREATE INDEX IDX_RES_PASS
ON [RESERVATION_PASSENGER](passenger_id, reservation_id);

CREATE INDEX IDX_RES_SERVICE
ON [RESERVATION_SERVICE](service_id, passenger_id);

CREATE INDEX IDX_EXCUR_BOOK
ON [EXCURSION_BOOKING](voyage_excursion_id, passenger_id);