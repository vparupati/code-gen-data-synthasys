-- ============================================================================
-- PostgreSQL Database Initialization Script
-- ============================================================================
-- This script creates the complete schema for the payment processing model
-- ============================================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===== ENUM TYPES =====
CREATE TYPE message_state AS ENUM (
  'RECEIVED','VALIDATED','ENRICHED','ROUTED','PARTIALLY_ACCEPTED',
  'ACCEPTED','SENT_TO_SCHEME','SETTLED','REJECTED','FAILED'
);

CREATE TYPE payment_state AS ENUM (
  'RECEIVED','VALIDATED','PENDING_FUNDS','ROUTED',
  'SENT_TO_SCHEME','SETTLED','REJECTED','FAILED'
);

CREATE TYPE party_type AS ENUM ('DEBTOR','CREDITOR','INTERMEDIARY','BOTH');
CREATE TYPE identifier_type AS ENUM ('IBAN','BBAN','ACCOUNT_NO','SORT_CODE','BIC','IFSC','LEI','OTHER');

CREATE TYPE currency_code AS ENUM (
  'AED','AUD','BRL','CAD','CHF','CNY','DKK','EUR','GBP','HKD','INR','JPY','KRW',
  'MXN','NOK','NZD','PLN','SEK','SGD','TRY','USD','ZAR'
);

CREATE TYPE route_role AS ENUM ('SENDER_BANK','CORRESPONDENT','INTERMEDIARY','RECEIVER_BANK');

-- ===== REFERENCE: INSTITUTIONS / PARTIES =====
CREATE TABLE institutions (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  legal_name       TEXT NOT NULL,
  bic              TEXT,
  lei              TEXT,
  country_code     CHAR(2),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (bic),
  UNIQUE (lei)
);

CREATE TABLE parties (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  party_type       party_type NOT NULL,
  display_name     TEXT NOT NULL,
  institution_id   UUID REFERENCES institutions(id) ON UPDATE CASCADE ON DELETE SET NULL,
  email            TEXT,
  phone            TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE party_identifiers (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  party_id         UUID NOT NULL REFERENCES parties(id) ON UPDATE CASCADE ON DELETE CASCADE,
  id_type          identifier_type NOT NULL,
  id_value         TEXT NOT NULL,
  scheme           TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (party_id, id_type, id_value)
);

-- ===== MESSAGES =====
CREATE TABLE messages (
  id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  external_ref           TEXT,
  source_system          TEXT NOT NULL,
  message_state          message_state NOT NULL DEFAULT 'RECEIVED',
  total_payments         INT NOT NULL DEFAULT 0,
  received_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_state_changed_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  attributes             JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (external_ref)
);

CREATE TABLE message_events (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id       UUID NOT NULL REFERENCES messages(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  seq_no           BIGSERIAL NOT NULL,
  from_state       message_state,
  to_state         message_state NOT NULL,
  reason_code      TEXT,
  reason_text      TEXT,
  actor_type       TEXT NOT NULL DEFAULT 'SYSTEM',
  actor_id         TEXT,
  occurred_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata         JSONB NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE (message_id, seq_no)
);

-- ===== PAYMENTS =====
CREATE TABLE payments (
  id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id             UUID NOT NULL REFERENCES messages(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  payment_ref            TEXT,
  scheme                 TEXT NOT NULL,
  amount                 NUMERIC(19,4) NOT NULL,
  currency               currency_code NOT NULL,
  payment_state          payment_state NOT NULL DEFAULT 'RECEIVED',
  last_state_changed_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  instructed_on          TIMESTAMPTZ NOT NULL DEFAULT now(),
  debtor_snapshot        JSONB NOT NULL,
  creditor_snapshot      JSONB NOT NULL,
  debtor_id              UUID REFERENCES parties(id) ON UPDATE CASCADE ON DELETE SET NULL,
  creditor_id            UUID REFERENCES parties(id) ON UPDATE CASCADE ON DELETE SET NULL,
  route_summary          JSONB NOT NULL DEFAULT '{}'::jsonb,
  attributes             JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (payment_ref)
);

CREATE TABLE payment_events (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  payment_id       UUID NOT NULL REFERENCES payments(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  seq_no           BIGSERIAL NOT NULL,
  from_state       payment_state,
  to_state         payment_state NOT NULL,
  reason_code      TEXT,
  reason_text      TEXT,
  actor_type       TEXT NOT NULL DEFAULT 'SYSTEM',
  actor_id         TEXT,
  occurred_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata         JSONB NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE (payment_id, seq_no)
);

CREATE TABLE payment_route_steps (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  payment_id       UUID NOT NULL REFERENCES payments(id) ON UPDATE CASCADE ON DELETE CASCADE,
  step_no          INT NOT NULL,
  role             route_role NOT NULL,
  institution_id   UUID REFERENCES institutions(id) ON UPDATE CASCADE ON DELETE SET NULL,
  institution_name TEXT NOT NULL,
  bic              TEXT,
  lei              TEXT,
  country_code     CHAR(2),
  metadata         JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (payment_id, step_no)
);

-- Optional: whitelist of allowed transitions
CREATE TABLE valid_message_transitions (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  from_state       message_state,
  to_state         message_state NOT NULL,
  UNIQUE (from_state, to_state)
);

CREATE TABLE valid_payment_transitions (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  from_state       payment_state,
  to_state         payment_state NOT NULL,
  UNIQUE (from_state, to_state)
);

-- ===== INDEXES =====
CREATE INDEX idx_payments_message_id           ON payments (message_id);
CREATE INDEX idx_payment_events_payment_id     ON payment_events (payment_id);
CREATE INDEX idx_message_events_message_id     ON message_events (message_id);
CREATE INDEX idx_route_steps_payment_id        ON payment_route_steps (payment_id);

CREATE INDEX idx_messages_state_time           ON messages (message_state, last_state_changed_at DESC);
CREATE INDEX idx_payments_state_time           ON payments (payment_state, last_state_changed_at DESC);

CREATE INDEX idx_payments_ref                  ON payments (payment_ref);
CREATE INDEX idx_payments_scheme               ON payments (scheme, created_at DESC);

CREATE INDEX idx_messages_attributes           ON messages USING GIN (attributes);
CREATE INDEX idx_payments_attributes           ON payments USING GIN (attributes);
CREATE INDEX idx_payments_route_summary        ON payments USING GIN (route_summary);

-- ===== SAMPLE DATA FOR TESTING =====
-- Insert sample institutions
DO $$
DECLARE
    bank_a_id UUID;
    bank_b_id UUID;
BEGIN
    INSERT INTO institutions (legal_name, bic, lei, country_code) VALUES
      ('Bank A UK', 'BKUKGB22XXX', '213800D1EI4B9WTWWD28', 'GB')
    RETURNING id INTO bank_a_id;
    
    INSERT INTO institutions (legal_name, bic, lei, country_code) VALUES
      ('Bank B UK', 'BKBKGB2LXXX', '5493000KJTIIGC8Y1R13', 'GB')
    RETURNING id INTO bank_b_id;
    
    INSERT INTO institutions (legal_name, bic, lei, country_code) VALUES
      ('Correspondent Bank AG', 'EXCBDEFFXXX', '5493001KJTIIGC8Y1R12', 'DE');

    -- Insert sample parties
    INSERT INTO parties (party_type, display_name, institution_id, email) VALUES
      ('DEBTOR', 'Acme Manufacturing Ltd', bank_a_id, 'ap@acme.example'),
      ('CREDITOR', 'Widgets Wholesale PLC', bank_b_id, 'info@widgets.example');

    -- Insert sample message
    INSERT INTO messages (external_ref, source_system, message_state, total_payments) VALUES
      ('BATCH_TEST_001', 'TestSystem', 'RECEIVED', 0);
END $$;

