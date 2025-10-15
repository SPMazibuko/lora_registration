-- Postgres schema blueprint for the biometric access control platform.
-- This file provides illustrative CREATE TABLE statements with constraints,
-- enums, and RLS policies to be managed via Hasura migrations.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS vector; -- For embedding vectors

-- Enumerations
CREATE TYPE user_status AS ENUM ('active', 'pending', 'suspended', 'disabled');
CREATE TYPE device_status AS ENUM ('active', 'maintenance', 'decommissioned');
CREATE TYPE auth_decision AS ENUM ('allow', 'deny', 'review');
CREATE TYPE auth_mode AS ENUM ('face_only', 'mfa', 'override');
CREATE TYPE actor_type AS ENUM ('user', 'device', 'system');

CREATE TABLE roles (
    id          SERIAL PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE locations (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        TEXT NOT NULL,
    metadata    JSONB DEFAULT '{}'::JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            TEXT NOT NULL,
    email           CITEXT NOT NULL UNIQUE,
    role_id         INT NOT NULL REFERENCES roles(id),
    status          user_status NOT NULL DEFAULT 'pending',
    avatar_url      TEXT,
    metadata        JSONB DEFAULT '{}'::JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_login_at   TIMESTAMPTZ
);

CREATE INDEX users_role_id_idx ON users(role_id);
CREATE INDEX users_status_idx ON users(status);

CREATE TABLE devices (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            TEXT NOT NULL,
    location_id     UUID NOT NULL REFERENCES locations(id),
    status          device_status NOT NULL DEFAULT 'active',
    firmware_version TEXT,
    last_seen_at    TIMESTAMPTZ,
    metadata        JSONB DEFAULT '{}'::JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX devices_location_id_idx ON devices(location_id);
CREATE INDEX devices_status_idx ON devices(status);

CREATE TABLE device_secrets (
    id              BIGSERIAL PRIMARY KEY,
    device_id       UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    secret_hash     TEXT NOT NULL,
    rotated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at      TIMESTAMPTZ,
    created_by      UUID REFERENCES users(id),
    metadata        JSONB DEFAULT '{}'::JSONB
);

CREATE INDEX device_secrets_device_idx ON device_secrets(device_id);

CREATE TABLE enrollments (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id       UUID REFERENCES devices(id) ON DELETE SET NULL,
    sample_count    INT NOT NULL DEFAULT 0,
    approved_by     UUID REFERENCES users(id),
    status          TEXT NOT NULL DEFAULT 'pending',
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX enrollments_user_idx ON enrollments(user_id);
CREATE INDEX enrollments_device_idx ON enrollments(device_id);

CREATE TABLE face_embeddings (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    embedding       vector(512) NOT NULL,
    model_version   TEXT NOT NULL,
    quality_score   NUMERIC(5,2),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    source_device_id UUID REFERENCES devices(id),
    metadata        JSONB DEFAULT '{}'::JSONB
);

CREATE INDEX face_embeddings_user_idx ON face_embeddings(user_id);
CREATE INDEX face_embeddings_model_idx ON face_embeddings(model_version);

CREATE TABLE auth_events (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id       UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    user_id         UUID REFERENCES users(id),
    similarity      NUMERIC(6,4),
    decision        auth_decision NOT NULL,
    mode            auth_mode NOT NULL DEFAULT 'face_only',
    payload_json    JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    model_version   TEXT NOT NULL,
    latency_ms      INT,
    location_id     UUID REFERENCES locations(id),
    reason          TEXT
);

CREATE INDEX auth_events_device_idx ON auth_events(device_id);
CREATE INDEX auth_events_user_idx ON auth_events(user_id);
CREATE INDEX auth_events_created_at_idx ON auth_events(created_at DESC);

CREATE TABLE policies (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_id     UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
    allowed_role    TEXT NOT NULL,
    schedule        JSONB NOT NULL, -- e.g., { "weekdays": ["mon", ...], "from": "08:00", "to": "18:00" }
    metadata        JSONB DEFAULT '{}'::JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX policies_location_idx ON policies(location_id);

CREATE TABLE sessions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id       UUID REFERENCES devices(id),
    refresh_token   TEXT,
    expires_at      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at      TIMESTAMPTZ
);

CREATE INDEX sessions_user_idx ON sessions(user_id);

CREATE TABLE audit_logs (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_type      actor_type NOT NULL,
    actor_id        UUID,
    action          TEXT NOT NULL,
    resource        TEXT NOT NULL,
    metadata        JSONB DEFAULT '{}'::JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX audit_logs_actor_idx ON audit_logs(actor_type, actor_id);
CREATE INDEX audit_logs_created_at_idx ON audit_logs(created_at DESC);

-- Example RLS policy placeholders (implementation via Hasura permissions)
-- Policies to be translated to Hasura metadata using session variables.
-- Example: allow operator to view users for assigned locations.
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY operator_select_users ON users
--     USING (current_setting('hasura.user', true)::UUID = id);

