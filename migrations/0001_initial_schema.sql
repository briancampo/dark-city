-- 0001_initial_schema.sql
-- Base schema provisioning for Dark City:
-- 1. pgvector extension
-- 2. Multi-tenant world instances (Decision 0003, Blueprint §10.2)
-- 3. Scoped citizens and simulation events
-- 4. Citizen-less world events (Decision 0004, Blueprint §4.1)
-- 5. Unified observable_events view for spatial perception/observation queries

-- Enable pgvector extension for high-dimensional semantic memory embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- -----------------------------------------------------------------------------
-- 1. Worlds: Running isolated simulation instances (Blueprint §10.2, Decision 0003)
-- -----------------------------------------------------------------------------
CREATE TABLE worlds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scenario_id TEXT NOT NULL,
    name TEXT,
    status VARCHAR(16) NOT NULL DEFAULT 'initializing',
    sim_clock TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- 2. Citizens: Roster entities scoped to an isolated world instance
-- -----------------------------------------------------------------------------
CREATE TABLE citizens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    world_id UUID NOT NULL REFERENCES worlds(id),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_citizens_world_id ON citizens (world_id);

-- -----------------------------------------------------------------------------
-- 3. Simulation Events: Attributed actions, speech, and tool calls (Blueprint §4.1)
-- -----------------------------------------------------------------------------
CREATE TABLE simulation_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    world_id UUID NOT NULL REFERENCES worlds(id),
    citizen_id UUID REFERENCES citizens(id),
    event_type VARCHAR(64) NOT NULL,
    location_node_id TEXT,
    payload JSONB NOT NULL,
    salience SMALLINT NOT NULL CHECK (salience BETWEEN 1 AND 10),
    -- NOTE: occurred_at MUST be explicitly passed from the world's sim_clock.
    -- It must NEVER default to wall-clock now() (Decision 0004).
    occurred_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_simulation_events_world_citizen ON simulation_events (world_id, citizen_id);
CREATE INDEX idx_simulation_events_world_occurred ON simulation_events (world_id, occurred_at);
CREATE INDEX idx_simulation_events_world_location ON simulation_events (world_id, location_node_id) WHERE location_node_id IS NOT NULL;

-- -----------------------------------------------------------------------------
-- 4. World Events: Ambient/citizen-less events (Decision 0004, Blueprint §4.1)
-- -----------------------------------------------------------------------------
CREATE TABLE world_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    world_id UUID NOT NULL REFERENCES worlds(id),
    source VARCHAR(20) NOT NULL
        CHECK (source IN ('scenario_scripted', 'threshold_crossing', 'citizen_triggered')),
    origin_citizen_id UUID REFERENCES citizens(id),
    event_type VARCHAR(64) NOT NULL,
    location_node_id TEXT,
    payload JSONB NOT NULL,
    salience SMALLINT NOT NULL CHECK (salience BETWEEN 1 AND 10),
    -- NOTE: occurred_at MUST be explicitly passed from the world's sim_clock.
    -- It must NEVER default to wall-clock now() (Decision 0004).
    occurred_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_world_events_world_occurred ON world_events (world_id, occurred_at);
CREATE INDEX idx_world_events_world_location ON world_events (world_id, location_node_id) WHERE location_node_id IS NOT NULL;

-- -----------------------------------------------------------------------------
-- 5. Observable Events: Single read-surface union view for Observation module & Narrator
-- -----------------------------------------------------------------------------
CREATE VIEW observable_events AS
SELECT world_id, id AS event_id, citizen_id AS actor_citizen_id, location_node_id, occurred_at, salience, payload
FROM simulation_events
UNION ALL
SELECT world_id, id AS event_id, origin_citizen_id AS actor_citizen_id, location_node_id, occurred_at, salience, payload
FROM world_events;
