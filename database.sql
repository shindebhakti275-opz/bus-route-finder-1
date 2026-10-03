-- PostgreSQL schema for Bus Route Finder and Ticket Booking System.
-- The app's `flask --app app init-db` command creates these tables and seeds
-- fictional demonstration records. This file is also provided for inspection
-- and manual database setup.
SET TIME ZONE 'Asia/Kolkata';

CREATE TABLE IF NOT EXISTS "user" (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    mobile VARCHAR(20) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bus_stop (
    id SERIAL PRIMARY KEY,
    name VARCHAR(120) NOT NULL UNIQUE,
    area VARCHAR(120) NOT NULL DEFAULT '',
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bus_route (
    id SERIAL PRIMARY KEY,
    name VARCHAR(120) NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS route_stop (
    id SERIAL PRIMARY KEY,
    route_id INTEGER NOT NULL REFERENCES bus_route(id) ON DELETE CASCADE,
    stop_id INTEGER NOT NULL REFERENCES bus_stop(id) ON DELETE CASCADE,
    position INTEGER NOT NULL CHECK (position >= 0),
    UNIQUE (route_id, position),
    UNIQUE (route_id, stop_id)
);

CREATE TABLE IF NOT EXISTS bus (
    id SERIAL PRIMARY KEY,
    bus_number VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    route_id INTEGER NOT NULL REFERENCES bus_route(id),
    first_bus_time VARCHAR(5) NOT NULL DEFAULT '06:00',
    last_bus_time VARCHAR(5) NOT NULL DEFAULT '22:00',
    frequency_mins INTEGER NOT NULL DEFAULT 20 CHECK (frequency_mins > 0),
    base_fare_per_segment NUMERIC(8,2) NOT NULL DEFAULT 10 CHECK (base_fare_per_segment > 0),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS booking (
    id SERIAL PRIMARY KEY,
    reference VARCHAR(24) NOT NULL UNIQUE,
    user_id INTEGER NOT NULL REFERENCES "user"(id),
    bus_id INTEGER NOT NULL REFERENCES bus(id),
    source_stop_id INTEGER NOT NULL REFERENCES bus_stop(id),
    destination_stop_id INTEGER NOT NULL REFERENCES bus_stop(id),
    travel_at TIMESTAMPTZ NOT NULL,
    passenger_category VARCHAR(30) NOT NULL
        CHECK (passenger_category IN ('Adult', 'Child', 'Senior Citizen')),
    passenger_count INTEGER NOT NULL CHECK (passenger_count BETWEEN 1 AND 8),
    fare_each NUMERIC(8,2) NOT NULL CHECK (fare_each >= 0),
    total_fare NUMERIC(8,2) NOT NULL CHECK (total_fare >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'paid')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (source_stop_id <> destination_stop_id)
);

CREATE TABLE IF NOT EXISTS payment (
    id SERIAL PRIMARY KEY,
    payment_id VARCHAR(32) NOT NULL UNIQUE,
    booking_id INTEGER NOT NULL UNIQUE REFERENCES booking(id),
    mode VARCHAR(30) NOT NULL CHECK (mode IN ('UPI', 'Card', 'Net Banking')),
    amount NUMERIC(8,2) NOT NULL CHECK (amount >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'successful'
        CHECK (status IN ('successful')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS complaint (
    id SERIAL PRIMARY KEY,
    reference VARCHAR(24) NOT NULL UNIQUE,
    user_id INTEGER REFERENCES "user"(id),
    name VARCHAR(120) NOT NULL,
    contact VARCHAR(255) NOT NULL,
    bus_number VARCHAR(30) NOT NULL DEFAULT '',
    route_name VARCHAR(120) NOT NULL DEFAULT '',
    description TEXT NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'submitted'
        CHECK (status IN ('submitted', 'in progress', 'resolved')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS ix_user_email ON "user"(email);
CREATE INDEX IF NOT EXISTS ix_booking_user_created ON booking(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS ix_complaint_created ON complaint(created_at DESC);