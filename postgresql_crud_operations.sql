-- ============================================================================
-- PostgreSQL CRUD Operations for Payment Processing Model
-- ============================================================================
-- Comprehensive SQL examples for training SLM on text-to-SQL and SQL↔NoSQL
-- ============================================================================

-- ============================================================================
-- INSTITUTIONS - CREATE Operations
-- ============================================================================

-- Insert a single institution
INSERT INTO institutions (legal_name, bic, lei, country_code)
VALUES ('Example Bank Ltd', 'EXBKGB22XXX', '5493001KJTIIGC8Y1R12', 'GB');

-- Insert institution with only required fields
INSERT INTO institutions (legal_name)
VALUES ('Simple Bank Inc');

-- Insert multiple institutions (bulk insert)
INSERT INTO institutions (legal_name, bic, lei, country_code) VALUES
  ('Bank A UK', 'BKUKGB22XXX', '213800D1EI4B9WTWWD28', 'GB'),
  ('Bank B UK', 'BKBKGB2LXXX', '5493000KJTIIGC8Y1R13', 'GB'),
  ('Correspondent Bank AG', 'EXCBDEFFXXX', '5493001KJTIIGC8Y1R12', 'DE');

-- Insert with explicit ID (if needed)
INSERT INTO institutions (id, legal_name, bic, country_code)
VALUES (gen_random_uuid(), 'Custom Bank', 'CUSTGB22XXX', 'GB');

-- ============================================================================
-- INSTITUTIONS - READ Operations
-- ============================================================================

-- Get institution by ID
SELECT * FROM institutions WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Get institution by BIC
SELECT * FROM institutions WHERE bic = 'EXBKGB22XXX';

-- Get institution by LEI
SELECT * FROM institutions WHERE lei = '5493001KJTIIGC8Y1R12';

-- Get all institutions
SELECT * FROM institutions ORDER BY created_at DESC;

-- Get institutions by country
SELECT * FROM institutions WHERE country_code = 'GB' ORDER BY legal_name;

-- Get institutions with pagination (limit/offset)
SELECT * FROM institutions ORDER BY created_at DESC LIMIT 10 OFFSET 0;

-- Get institutions with pagination (fetch/offset - SQL standard)
SELECT * FROM institutions ORDER BY created_at DESC OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- Search institutions by name pattern
SELECT * FROM institutions WHERE legal_name ILIKE '%Bank%' ORDER BY legal_name;

-- Get institutions created in date range
SELECT * FROM institutions 
WHERE created_at >= '2025-01-01'::timestamptz 
  AND created_at < '2025-12-31'::timestamptz
ORDER BY created_at DESC;

-- Count institutions by country
SELECT country_code, COUNT(*) as institution_count 
FROM institutions 
GROUP BY country_code 
ORDER BY institution_count DESC;

-- Get institutions with BIC or LEI (not null)
SELECT * FROM institutions 
WHERE bic IS NOT NULL OR lei IS NOT NULL
ORDER BY legal_name;

-- ============================================================================
-- INSTITUTIONS - UPDATE Operations
-- ============================================================================

-- Update single field
UPDATE institutions 
SET legal_name = 'Updated Bank Name Ltd' 
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Update multiple fields
UPDATE institutions 
SET legal_name = 'New Bank Name',
    bic = 'NEWBGB22XXX',
    updated_at = now()
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Update with conditional logic
UPDATE institutions 
SET country_code = 'US',
    updated_at = now()
WHERE country_code IS NULL AND legal_name LIKE '%Bank%';

-- Update all institutions' updated_at timestamp
UPDATE institutions 
SET updated_at = now()
WHERE updated_at < now() - INTERVAL '1 day';

-- ============================================================================
-- INSTITUTIONS - DELETE Operations
-- ============================================================================

-- Delete institution by ID
DELETE FROM institutions WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Delete institutions by country (if no foreign key restrictions)
DELETE FROM institutions WHERE country_code = 'XX';

-- Delete institutions with no BIC or LEI
DELETE FROM institutions WHERE bic IS NULL AND lei IS NULL;

-- ============================================================================
-- PARTIES - CREATE Operations
-- ============================================================================

-- Insert a single party
INSERT INTO parties (party_type, display_name, institution_id, email, phone)
VALUES ('DEBTOR', 'Acme Manufacturing Ltd', '550e8400-e29b-41d4-a716-446655440000', 'ap@acme.example', '+44-20-1234-5678');

-- Insert party without institution (standalone)
INSERT INTO parties (party_type, display_name, email)
VALUES ('CREDITOR', 'Widgets Wholesale PLC', 'info@widgets.example');

-- Insert party with all fields
INSERT INTO parties (party_type, display_name, institution_id, email, phone)
VALUES ('BOTH', 'Universal Trading Co', '550e8400-e29b-41d4-a716-446655440001', 'contact@universal.example', '+1-555-123-4567');

-- Bulk insert parties
INSERT INTO parties (party_type, display_name, institution_id, email) VALUES
  ('DEBTOR', 'Company A', '550e8400-e29b-41d4-a716-446655440000', 'a@company.example'),
  ('CREDITOR', 'Company B', '550e8400-e29b-41d4-a716-446655440001', 'b@company.example'),
  ('INTERMEDIARY', 'Company C', NULL, 'c@company.example');

-- ============================================================================
-- PARTIES - READ Operations
-- ============================================================================

-- Get party by ID
SELECT * FROM parties WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Get parties by type
SELECT * FROM parties WHERE party_type = 'DEBTOR' ORDER BY display_name;

-- Get parties with institution (join)
SELECT p.*, i.legal_name as institution_name, i.bic
FROM parties p
LEFT JOIN institutions i ON p.institution_id = i.id
WHERE p.party_type = 'DEBTOR';

-- Get parties by institution
SELECT * FROM parties 
WHERE institution_id = '550e8400-e29b-41d4-a716-446655440000'
ORDER BY display_name;

-- Search parties by name
SELECT * FROM parties 
WHERE display_name ILIKE '%Manufacturing%'
ORDER BY display_name;

-- Get parties with pagination
SELECT * FROM parties 
ORDER BY created_at DESC 
LIMIT 20 OFFSET 0;

-- Get parties created in date range
SELECT * FROM parties 
WHERE created_at >= '2025-01-01'::timestamptz 
  AND created_at < '2025-12-31'::timestamptz
ORDER BY created_at DESC;

-- Count parties by type
SELECT party_type, COUNT(*) as count 
FROM parties 
GROUP BY party_type;

-- Get parties with email domain
SELECT * FROM parties 
WHERE email LIKE '%@example.com'
ORDER BY display_name;

-- ============================================================================
-- PARTIES - UPDATE Operations
-- ============================================================================

-- Update single field
UPDATE parties 
SET display_name = 'Updated Company Name' 
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Update multiple fields
UPDATE parties 
SET display_name = 'New Company Name',
    email = 'newemail@example.com',
    phone = '+44-20-9999-9999',
    updated_at = now()
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Update party type
UPDATE parties 
SET party_type = 'BOTH',
    updated_at = now()
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Update institution association
UPDATE parties 
SET institution_id = '550e8400-e29b-41d4-a716-446655440001',
    updated_at = now()
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- ============================================================================
-- PARTIES - DELETE Operations
-- ============================================================================

-- Delete party by ID
DELETE FROM parties WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Delete parties by type (if no foreign key restrictions)
DELETE FROM parties WHERE party_type = 'INTERMEDIARY';

-- ============================================================================
-- PARTY_IDENTIFIERS - CREATE Operations
-- ============================================================================

-- Insert single identifier
INSERT INTO party_identifiers (party_id, id_type, id_value, scheme)
VALUES ('550e8400-e29b-41d4-a716-446655440000', 'ACCOUNT_NO', '12345678', 'GB-ACCOUNT');

-- Insert multiple identifiers for same party
INSERT INTO party_identifiers (party_id, id_type, id_value, scheme) VALUES
  ('550e8400-e29b-41d4-a716-446655440000', 'ACCOUNT_NO', '12345678', 'GB-ACCOUNT'),
  ('550e8400-e29b-41d4-a716-446655440000', 'SORT_CODE', '12-34-56', 'GB-SORTCODE'),
  ('550e8400-e29b-41d4-a716-446655440000', 'IBAN', 'GB82WEST12345698765432', 'ISO13616');

-- Insert identifier without scheme
INSERT INTO party_identifiers (party_id, id_type, id_value)
VALUES ('550e8400-e29b-41d4-a716-446655440000', 'LEI', '5493001KJTIIGC8Y1R12');

-- ============================================================================
-- PARTY_IDENTIFIERS - READ Operations
-- ============================================================================

-- Get identifiers by party ID
SELECT * FROM party_identifiers 
WHERE party_id = '550e8400-e29b-41d4-a716-446655440000'
ORDER BY id_type, created_at;

-- Get identifier by value
SELECT * FROM party_identifiers 
WHERE id_value = '12345678';

-- Get identifiers by type
SELECT * FROM party_identifiers 
WHERE id_type = 'IBAN'
ORDER BY created_at DESC;

-- Get identifiers with party details (join)
SELECT pi.*, p.display_name, p.party_type
FROM party_identifiers pi
JOIN parties p ON pi.party_id = p.id
WHERE pi.id_type = 'IBAN';

-- Get identifiers by scheme
SELECT * FROM party_identifiers 
WHERE scheme = 'GB-ACCOUNT'
ORDER BY created_at DESC;

-- Search identifiers by value pattern
SELECT * FROM party_identifiers 
WHERE id_value LIKE 'GB%'
ORDER BY id_type;

-- Get all identifiers for multiple parties
SELECT * FROM party_identifiers 
WHERE party_id IN (
  '550e8400-e29b-41d4-a716-446655440000',
  '550e8400-e29b-41d4-a716-446655440001'
)
ORDER BY party_id, id_type;

-- ============================================================================
-- PARTY_IDENTIFIERS - UPDATE Operations
-- ============================================================================

-- Update identifier scheme
UPDATE party_identifiers 
SET scheme = 'NEW-SCHEME'
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Update identifier value (rare, but possible)
UPDATE party_identifiers 
SET id_value = 'NEW_VALUE',
    scheme = 'UPDATED-SCHEME'
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- ============================================================================
-- PARTY_IDENTIFIERS - DELETE Operations
-- ============================================================================

-- Delete identifier by ID
DELETE FROM party_identifiers WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Delete all identifiers for a party
DELETE FROM party_identifiers 
WHERE party_id = '550e8400-e29b-41d4-a716-446655440000';

-- Delete identifiers by type
DELETE FROM party_identifiers 
WHERE party_id = '550e8400-e29b-41d4-a716-446655440000' 
  AND id_type = 'SORT_CODE';

-- ============================================================================
-- MESSAGES - CREATE Operations
-- ============================================================================

-- Insert a single message
INSERT INTO messages (external_ref, source_system, message_state, total_payments, attributes)
VALUES ('BATCH_2025-11-08_001', 'UpstreamGateway-A', 'RECEIVED', 0, '{"format": "ISO20022-pacs.008"}'::jsonb);

-- Insert message with all fields
INSERT INTO messages (external_ref, source_system, message_state, total_payments, received_at, attributes)
VALUES (
  'BATCH_2025-11-08_002',
  'UpstreamGateway-B',
  'VALIDATED',
  5,
  '2025-11-08T10:00:00Z'::timestamptz,
  '{"format": "ISO20022-pacs.008", "file_hash": "sha256:abcd1234"}'::jsonb
);

-- Insert message with default state
INSERT INTO messages (external_ref, source_system, total_payments)
VALUES ('BATCH_2025-11-08_003', 'UpstreamGateway-C', 10);

-- Bulk insert messages
INSERT INTO messages (external_ref, source_system, message_state, total_payments) VALUES
  ('BATCH_001', 'System-A', 'RECEIVED', 2),
  ('BATCH_002', 'System-B', 'RECEIVED', 3),
  ('BATCH_003', 'System-A', 'VALIDATED', 1);

-- ============================================================================
-- MESSAGES - READ Operations
-- ============================================================================

-- Get message by ID
SELECT * FROM messages WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Get message by external_ref
SELECT * FROM messages WHERE external_ref = 'BATCH_2025-11-08_001';

-- Get messages by state
SELECT * FROM messages 
WHERE message_state = 'RECEIVED'
ORDER BY received_at DESC;

-- Get messages by source system
SELECT * FROM messages 
WHERE source_system = 'UpstreamGateway-A'
ORDER BY received_at DESC;

-- Get messages with pagination
SELECT * FROM messages 
ORDER BY received_at DESC 
LIMIT 50 OFFSET 0;

-- Get messages in date range
SELECT * FROM messages 
WHERE received_at >= '2025-11-08T00:00:00Z'::timestamptz 
  AND received_at < '2025-11-09T00:00:00Z'::timestamptz
ORDER BY received_at DESC;

-- Get messages by state and time range
SELECT * FROM messages 
WHERE message_state = 'SETTLED'
  AND last_state_changed_at >= now() - INTERVAL '7 days'
ORDER BY last_state_changed_at DESC;

-- Query JSONB attributes
SELECT * FROM messages 
WHERE attributes->>'format' = 'ISO20022-pacs.008';

-- Query JSONB with contains
SELECT * FROM messages 
WHERE attributes @> '{"format": "ISO20022-pacs.008"}'::jsonb;

-- Get messages with attribute key exists
SELECT * FROM messages 
WHERE attributes ? 'file_hash';

-- Count messages by state
SELECT message_state, COUNT(*) as count 
FROM messages 
GROUP BY message_state
ORDER BY count DESC;

-- Count messages by source system
SELECT source_system, COUNT(*) as count, 
       SUM(total_payments) as total_payment_count
FROM messages 
GROUP BY source_system
ORDER BY count DESC;

-- Get messages with payment count filter
SELECT * FROM messages 
WHERE total_payments > 10
ORDER BY total_payments DESC;

-- ============================================================================
-- MESSAGES - UPDATE Operations
-- ============================================================================

-- Update message state
UPDATE messages 
SET message_state = 'VALIDATED',
    last_state_changed_at = now(),
    updated_at = now()
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Update multiple fields
UPDATE messages 
SET message_state = 'ENRICHED',
    total_payments = 5,
    last_state_changed_at = now(),
    updated_at = now()
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Update JSONB attributes
UPDATE messages 
SET attributes = attributes || '{"new_key": "new_value"}'::jsonb,
    updated_at = now()
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Update specific JSONB key
UPDATE messages 
SET attributes = jsonb_set(attributes, '{priority}', '"HIGH"'),
    updated_at = now()
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Update total_payments
UPDATE messages 
SET total_payments = (
    SELECT COUNT(*) FROM payments WHERE message_id = messages.id
),
    updated_at = now()
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- ============================================================================
-- MESSAGES - DELETE Operations
-- ============================================================================

-- Delete message by ID (will fail if payments exist due to RESTRICT)
DELETE FROM messages WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Delete messages by external_ref
DELETE FROM messages WHERE external_ref = 'BATCH_2025-11-08_001';

-- ============================================================================
-- MESSAGE_EVENTS - CREATE Operations
-- ============================================================================

-- Insert single message event
INSERT INTO message_events (message_id, from_state, to_state, reason_code, reason_text, actor_type, actor_id, metadata)
VALUES (
  '550e8400-e29b-41d4-a716-446655440000',
  'RECEIVED',
  'VALIDATED',
  'VALIDATION_PASSED',
  'All validations passed successfully',
  'SYSTEM',
  'validation-svc',
  '{"aml": "PASS", "schema": "ISO20022"}'::jsonb
);

-- Insert event with null from_state (initial state)
INSERT INTO message_events (message_id, from_state, to_state, actor_type, metadata)
VALUES (
  '550e8400-e29b-41d4-a716-446655440000',
  NULL,
  'RECEIVED',
  'SYSTEM',
  '{"source": "UpstreamGateway-A"}'::jsonb
);

-- Bulk insert events for same message
INSERT INTO message_events (message_id, from_state, to_state, actor_type, actor_id, metadata) VALUES
  ('550e8400-e29b-41d4-a716-446655440000', NULL, 'RECEIVED', 'SYSTEM', 'ingestion-svc', '{}'::jsonb),
  ('550e8400-e29b-41d4-a716-446655440000', 'RECEIVED', 'VALIDATED', 'SYSTEM', 'validation-svc', '{"aml": "PASS"}'::jsonb),
  ('550e8400-e29b-41d4-a716-446655440000', 'VALIDATED', 'ENRICHED', 'SYSTEM', 'enrichment-svc', '{}'::jsonb);

-- ============================================================================
-- MESSAGE_EVENTS - READ Operations
-- ============================================================================

-- Get all events for a message (ordered by sequence)
SELECT * FROM message_events 
WHERE message_id = '550e8400-e29b-41d4-a716-446655440000'
ORDER BY seq_no ASC;

-- Get latest event for a message
SELECT * FROM message_events 
WHERE message_id = '550e8400-e29b-41d4-a716-446655440000'
ORDER BY seq_no DESC
LIMIT 1;

-- Get events by state transition
SELECT * FROM message_events 
WHERE from_state = 'RECEIVED' AND to_state = 'VALIDATED'
ORDER BY occurred_at DESC;

-- Get events by actor
SELECT * FROM message_events 
WHERE actor_type = 'SYSTEM' AND actor_id = 'validation-svc'
ORDER BY occurred_at DESC;

-- Get events in time range
SELECT * FROM message_events 
WHERE occurred_at >= '2025-11-08T00:00:00Z'::timestamptz 
  AND occurred_at < '2025-11-09T00:00:00Z'::timestamptz
ORDER BY occurred_at DESC;

-- Get events with message details (join)
SELECT me.*, m.external_ref, m.source_system
FROM message_events me
JOIN messages m ON me.message_id = m.id
WHERE me.to_state = 'REJECTED'
ORDER BY me.occurred_at DESC;

-- Query JSONB metadata
SELECT * FROM message_events 
WHERE metadata->>'aml' = 'PASS';

-- Get events with reason code
SELECT * FROM message_events 
WHERE reason_code IS NOT NULL
ORDER BY occurred_at DESC;

-- Count events by state transition
SELECT from_state, to_state, COUNT(*) as count
FROM message_events
GROUP BY from_state, to_state
ORDER BY count DESC;

-- ============================================================================
-- MESSAGE_EVENTS - UPDATE Operations
-- ============================================================================

-- Note: Events are typically immutable, but if needed:
-- Update event metadata
UPDATE message_events 
SET metadata = metadata || '{"updated": true}'::jsonb
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- ============================================================================
-- MESSAGE_EVENTS - DELETE Operations
-- ============================================================================

-- Delete event by ID
DELETE FROM message_events WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Delete all events for a message
DELETE FROM message_events 
WHERE message_id = '550e8400-e29b-41d4-a716-446655440000';

-- ============================================================================
-- PAYMENTS - CREATE Operations
-- ============================================================================

-- Insert single payment
INSERT INTO payments (
  message_id, payment_ref, scheme, amount, currency, payment_state,
  debtor_snapshot, creditor_snapshot, debtor_id, creditor_id, route_summary, attributes
)
VALUES (
  '550e8400-e29b-41d4-a716-446655440000',
  'PMT-2025-11-08-0001',
  'FPS',
  2000.00,
  'GBP',
  'RECEIVED',
  '{"display_name": "Acme Manufacturing Ltd", "identifiers": [{"type": "ACCOUNT_NO", "value": "12345678"}]}'::jsonb,
  '{"display_name": "Widgets Wholesale PLC", "identifiers": [{"type": "ACCOUNT_NO", "value": "87654321"}]}'::jsonb,
  '550e8400-e29b-41d4-a716-446655440001',
  '550e8400-e29b-41d4-a716-446655440002',
  '{"method": "DIRECT"}'::jsonb,
  '{"priority": "HIGH", "fee_model": "OUR"}'::jsonb
);

-- Insert payment with minimal fields
INSERT INTO payments (message_id, payment_ref, scheme, amount, currency, debtor_snapshot, creditor_snapshot)
VALUES (
  '550e8400-e29b-41d4-a716-446655440000',
  'PMT-2025-11-08-0002',
  'FPS',
  50.00,
  'GBP',
  '{"display_name": "Debtor Co"}'::jsonb,
  '{"display_name": "Creditor Co"}'::jsonb
);

-- Bulk insert payments
INSERT INTO payments (message_id, payment_ref, scheme, amount, currency, debtor_snapshot, creditor_snapshot) VALUES
  ('550e8400-e29b-41d4-a716-446655440000', 'PMT-001', 'FPS', 100.00, 'GBP', '{"display_name": "Debtor 1"}'::jsonb, '{"display_name": "Creditor 1"}'::jsonb),
  ('550e8400-e29b-41d4-a716-446655440000', 'PMT-002', 'FPS', 200.00, 'GBP', '{"display_name": "Debtor 2"}'::jsonb, '{"display_name": "Creditor 2"}'::jsonb),
  ('550e8400-e29b-41d4-a716-446655440000', 'PMT-003', 'SEPA', 500.00, 'EUR', '{"display_name": "Debtor 3"}'::jsonb, '{"display_name": "Creditor 3"}'::jsonb);

-- ============================================================================
-- PAYMENTS - READ Operations
-- ============================================================================

-- Get payment by ID
SELECT * FROM payments WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Get payment by payment_ref
SELECT * FROM payments WHERE payment_ref = 'PMT-2025-11-08-0001';

-- Get payments by message
SELECT * FROM payments 
WHERE message_id = '550e8400-e29b-41d4-a716-446655440000'
ORDER BY created_at;

-- Get payments by state
SELECT * FROM payments 
WHERE payment_state = 'SETTLED'
ORDER BY last_state_changed_at DESC;

-- Get payments by scheme
SELECT * FROM payments 
WHERE scheme = 'FPS'
ORDER BY created_at DESC;

-- Get payments by currency
SELECT * FROM payments 
WHERE currency = 'GBP'
ORDER BY amount DESC;

-- Get payments with amount filter
SELECT * FROM payments 
WHERE amount > 1000.00
ORDER BY amount DESC;

-- Get payments in amount range
SELECT * FROM payments 
WHERE amount >= 100.00 AND amount <= 5000.00
ORDER BY amount;

-- Get payments with pagination
SELECT * FROM payments 
ORDER BY created_at DESC 
LIMIT 100 OFFSET 0;

-- Get payments in date range
SELECT * FROM payments 
WHERE created_at >= '2025-11-08T00:00:00Z'::timestamptz 
  AND created_at < '2025-11-09T00:00:00Z'::timestamptz
ORDER BY created_at DESC;

-- Get payments by state and time range
SELECT * FROM payments 
WHERE payment_state = 'PENDING_FUNDS'
  AND last_state_changed_at >= now() - INTERVAL '1 hour'
ORDER BY last_state_changed_at DESC;

-- Query JSONB debtor_snapshot
SELECT * FROM payments 
WHERE debtor_snapshot->>'display_name' = 'Acme Manufacturing Ltd';

-- Query JSONB with contains
SELECT * FROM payments 
WHERE debtor_snapshot @> '{"display_name": "Acme Manufacturing Ltd"}'::jsonb;

-- Query nested JSONB (identifiers array)
SELECT * FROM payments 
WHERE debtor_snapshot->'identifiers' @> '[{"type": "ACCOUNT_NO"}]'::jsonb;

-- Get payments with route_summary query
SELECT * FROM payments 
WHERE route_summary->>'method' = 'DIRECT';

-- Get payments with attributes query
SELECT * FROM payments 
WHERE attributes->>'priority' = 'HIGH';

-- Get payments with message details (join)
SELECT p.*, m.external_ref, m.source_system, m.message_state
FROM payments p
JOIN messages m ON p.message_id = m.id
WHERE p.payment_state = 'REJECTED'
ORDER BY p.last_state_changed_at DESC;

-- Get payments with party details (join)
SELECT p.*, 
       pd.display_name as debtor_name,
       pc.display_name as creditor_name
FROM payments p
LEFT JOIN parties pd ON p.debtor_id = pd.id
LEFT JOIN parties pc ON p.creditor_id = pc.id
WHERE p.amount > 1000.00;

-- Count payments by state
SELECT payment_state, COUNT(*) as count, SUM(amount) as total_amount
FROM payments 
GROUP BY payment_state
ORDER BY count DESC;

-- Count payments by scheme
SELECT scheme, COUNT(*) as count, SUM(amount) as total_amount
FROM payments 
GROUP BY scheme
ORDER BY count DESC;

-- Count payments by currency
SELECT currency, COUNT(*) as count, SUM(amount) as total_amount
FROM payments 
GROUP BY currency
ORDER BY total_amount DESC;

-- Get payment statistics
SELECT 
  COUNT(*) as total_payments,
  SUM(amount) as total_amount,
  AVG(amount) as avg_amount,
  MIN(amount) as min_amount,
  MAX(amount) as max_amount,
  COUNT(DISTINCT currency) as currency_count
FROM payments;

-- ============================================================================
-- PAYMENTS - UPDATE Operations
-- ============================================================================

-- Update payment state
UPDATE payments 
SET payment_state = 'VALIDATED',
    last_state_changed_at = now(),
    updated_at = now()
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Update multiple fields
UPDATE payments 
SET payment_state = 'ROUTED',
    last_state_changed_at = now(),
    route_summary = '{"method": "DIRECT", "estimated_settlement": "2025-11-08T10:02:00Z"}'::jsonb,
    updated_at = now()
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Update JSONB attributes
UPDATE payments 
SET attributes = attributes || '{"new_key": "new_value"}'::jsonb,
    updated_at = now()
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Update specific JSONB key
UPDATE payments 
SET route_summary = jsonb_set(route_summary, '{method}', '"INDIRECT"'),
    updated_at = now()
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Update amount
UPDATE payments 
SET amount = 2500.00,
    updated_at = now()
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- ============================================================================
-- PAYMENTS - DELETE Operations
-- ============================================================================

-- Delete payment by ID (will fail if events/route_steps exist due to RESTRICT)
DELETE FROM payments WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Delete payments by payment_ref
DELETE FROM payments WHERE payment_ref = 'PMT-2025-11-08-0001';

-- ============================================================================
-- PAYMENT_EVENTS - CREATE Operations
-- ============================================================================

-- Insert single payment event
INSERT INTO payment_events (payment_id, from_state, to_state, reason_code, reason_text, actor_type, actor_id, metadata)
VALUES (
  '550e8400-e29b-41d4-a716-446655440000',
  'RECEIVED',
  'VALIDATED',
  'VALIDATION_PASSED',
  'Payment validated successfully',
  'SYSTEM',
  'validation-svc',
  '{"aml": "PASS", "schema": "ISO20022"}'::jsonb
);

-- Insert event with null from_state (initial state)
INSERT INTO payment_events (payment_id, from_state, to_state, actor_type, metadata)
VALUES (
  '550e8400-e29b-41d4-a716-446655440000',
  NULL,
  'RECEIVED',
  'SYSTEM',
  '{"source": "UpstreamGateway-A"}'::jsonb
);

-- Bulk insert events for same payment
INSERT INTO payment_events (payment_id, from_state, to_state, actor_type, actor_id, metadata) VALUES
  ('550e8400-e29b-41d4-a716-446655440000', NULL, 'RECEIVED', 'SYSTEM', 'ingestion-svc', '{}'::jsonb),
  ('550e8400-e29b-41d4-a716-446655440000', 'RECEIVED', 'VALIDATED', 'SYSTEM', 'validation-svc', '{"aml": "PASS"}'::jsonb),
  ('550e8400-e29b-41d4-a716-446655440000', 'VALIDATED', 'ROUTED', 'SYSTEM', 'routing-svc', '{"corridor": "FPS:Direct"}'::jsonb);

-- ============================================================================
-- PAYMENT_EVENTS - READ Operations
-- ============================================================================

-- Get all events for a payment (ordered by sequence)
SELECT * FROM payment_events 
WHERE payment_id = '550e8400-e29b-41d4-a716-446655440000'
ORDER BY seq_no ASC;

-- Get latest event for a payment
SELECT * FROM payment_events 
WHERE payment_id = '550e8400-e29b-41d4-a716-446655440000'
ORDER BY seq_no DESC
LIMIT 1;

-- Get events by state transition
SELECT * FROM payment_events 
WHERE from_state = 'RECEIVED' AND to_state = 'VALIDATED'
ORDER BY occurred_at DESC;

-- Get events by actor
SELECT * FROM payment_events 
WHERE actor_type = 'SYSTEM' AND actor_id = 'validation-svc'
ORDER BY occurred_at DESC;

-- Get events in time range
SELECT * FROM payment_events 
WHERE occurred_at >= '2025-11-08T00:00:00Z'::timestamptz 
  AND occurred_at < '2025-11-09T00:00:00Z'::timestamptz
ORDER BY occurred_at DESC;

-- Get events with payment details (join)
SELECT pe.*, p.payment_ref, p.scheme, p.amount, p.currency
FROM payment_events pe
JOIN payments p ON pe.payment_id = p.id
WHERE pe.to_state = 'REJECTED'
ORDER BY pe.occurred_at DESC;

-- Query JSONB metadata
SELECT * FROM payment_events 
WHERE metadata->>'aml' = 'PASS';

-- Get events with reason code
SELECT * FROM payment_events 
WHERE reason_code IS NOT NULL
ORDER BY occurred_at DESC;

-- Get events with specific reason code
SELECT * FROM payment_events 
WHERE reason_code = 'INSUFFICIENT_FUNDS'
ORDER BY occurred_at DESC;

-- Count events by state transition
SELECT from_state, to_state, COUNT(*) as count
FROM payment_events
GROUP BY from_state, to_state
ORDER BY count DESC;

-- ============================================================================
-- PAYMENT_EVENTS - UPDATE Operations
-- ============================================================================

-- Note: Events are typically immutable, but if needed:
-- Update event metadata
UPDATE payment_events 
SET metadata = metadata || '{"updated": true}'::jsonb
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- ============================================================================
-- PAYMENT_EVENTS - DELETE Operations
-- ============================================================================

-- Delete event by ID
DELETE FROM payment_events WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Delete all events for a payment
DELETE FROM payment_events 
WHERE payment_id = '550e8400-e29b-41d4-a716-446655440000';

-- ============================================================================
-- PAYMENT_ROUTE_STEPS - CREATE Operations
-- ============================================================================

-- Insert single route step
INSERT INTO payment_route_steps (payment_id, step_no, role, institution_id, institution_name, bic, lei, country_code, metadata)
VALUES (
  '550e8400-e29b-41d4-a716-446655440000',
  1,
  'SENDER_BANK',
  '550e8400-e29b-41d4-a716-446655440001',
  'Bank A UK',
  'BKUKGB22XXX',
  '213800D1EI4B9WTWWD28',
  'GB',
  '{"channel": "API"}'::jsonb
);

-- Insert route step without institution_id
INSERT INTO payment_route_steps (payment_id, step_no, role, institution_name, bic, country_code)
VALUES (
  '550e8400-e29b-41d4-a716-446655440000',
  2,
  'INTERMEDIARY',
  'Example Correspondent Bank AG',
  'EXCBDEFFXXX',
  'DE'
);

-- Bulk insert route steps for same payment
INSERT INTO payment_route_steps (payment_id, step_no, role, institution_name, bic, country_code, metadata) VALUES
  ('550e8400-e29b-41d4-a716-446655440000', 1, 'SENDER_BANK', 'Bank A UK', 'BKUKGB22XXX', 'GB', '{"channel": "API"}'::jsonb),
  ('550e8400-e29b-41d4-a716-446655440000', 2, 'INTERMEDIARY', 'Correspondent Bank AG', 'EXCBDEFFXXX', 'DE', '{"corridor": "GB-DE-GB"}'::jsonb),
  ('550e8400-e29b-41d4-a716-446655440000', 3, 'RECEIVER_BANK', 'Bank B UK', 'BKBKGB2LXXX', 'GB', '{}'::jsonb);

-- ============================================================================
-- PAYMENT_ROUTE_STEPS - READ Operations
-- ============================================================================

-- Get all route steps for a payment (ordered by step_no)
SELECT * FROM payment_route_steps 
WHERE payment_id = '550e8400-e29b-41d4-a716-446655440000'
ORDER BY step_no ASC;

-- Get route step by payment and step number
SELECT * FROM payment_route_steps 
WHERE payment_id = '550e8400-e29b-41d4-a716-446655440000' 
  AND step_no = 1;

-- Get route steps by role
SELECT * FROM payment_route_steps 
WHERE role = 'INTERMEDIARY'
ORDER BY created_at DESC;

-- Get route steps by BIC
SELECT * FROM payment_route_steps 
WHERE bic = 'EXCBDEFFXXX'
ORDER BY created_at DESC;

-- Get route steps by country
SELECT * FROM payment_route_steps 
WHERE country_code = 'GB'
ORDER BY payment_id, step_no;

-- Get route steps with payment details (join)
SELECT prs.*, p.payment_ref, p.scheme, p.amount, p.currency
FROM payment_route_steps prs
JOIN payments p ON prs.payment_id = p.id
WHERE prs.role = 'INTERMEDIARY'
ORDER BY prs.created_at DESC;

-- Get route steps with institution details (join)
SELECT prs.*, i.legal_name as institution_legal_name
FROM payment_route_steps prs
LEFT JOIN institutions i ON prs.institution_id = i.id
WHERE prs.payment_id = '550e8400-e29b-41d4-a716-446655440000'
ORDER BY prs.step_no;

-- Query JSONB metadata
SELECT * FROM payment_route_steps 
WHERE metadata->>'corridor' = 'GB-DE-GB';

-- Count route steps by role
SELECT role, COUNT(*) as count
FROM payment_route_steps
GROUP BY role
ORDER BY count DESC;

-- Get route steps count per payment
SELECT payment_id, COUNT(*) as step_count, MAX(step_no) as max_step
FROM payment_route_steps
GROUP BY payment_id
ORDER BY step_count DESC;

-- ============================================================================
-- PAYMENT_ROUTE_STEPS - UPDATE Operations
-- ============================================================================

-- Update route step metadata
UPDATE payment_route_steps 
SET metadata = metadata || '{"updated": true}'::jsonb
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Update route step institution details
UPDATE payment_route_steps 
SET institution_name = 'Updated Bank Name',
    bic = 'UPDTGB22XXX',
    metadata = '{"updated": true}'::jsonb
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- ============================================================================
-- PAYMENT_ROUTE_STEPS - DELETE Operations
-- ============================================================================

-- Delete route step by ID
DELETE FROM payment_route_steps WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Delete all route steps for a payment
DELETE FROM payment_route_steps 
WHERE payment_id = '550e8400-e29b-41d4-a716-446655440000';

-- Delete route step by payment and step number
DELETE FROM payment_route_steps 
WHERE payment_id = '550e8400-e29b-41d4-a716-446655440000' 
  AND step_no = 1;

-- ============================================================================
-- COMPLEX QUERIES - Multi-table Operations
-- ============================================================================

-- Get payment with full details (message, parties, route steps, events)
SELECT 
  p.*,
  m.external_ref as message_ref,
  m.source_system,
  pd.display_name as debtor_name,
  pc.display_name as creditor_name,
  (SELECT COUNT(*) FROM payment_route_steps WHERE payment_id = p.id) as route_step_count,
  (SELECT COUNT(*) FROM payment_events WHERE payment_id = p.id) as event_count
FROM payments p
JOIN messages m ON p.message_id = m.id
LEFT JOIN parties pd ON p.debtor_id = pd.id
LEFT JOIN parties pc ON p.creditor_id = pc.id
WHERE p.id = '550e8400-e29b-41d4-a716-446655440000';

-- Get message with all payments and their states
SELECT 
  m.*,
  COUNT(p.id) as payment_count,
  SUM(p.amount) as total_amount,
  COUNT(CASE WHEN p.payment_state = 'SETTLED' THEN 1 END) as settled_count,
  COUNT(CASE WHEN p.payment_state = 'REJECTED' THEN 1 END) as rejected_count
FROM messages m
LEFT JOIN payments p ON m.id = p.message_id
WHERE m.id = '550e8400-e29b-41d4-a716-446655440000'
GROUP BY m.id;

-- Get payment state transition timeline
SELECT 
  pe.seq_no,
  pe.from_state,
  pe.to_state,
  pe.occurred_at,
  pe.actor_type,
  pe.actor_id,
  pe.reason_code
FROM payment_events pe
WHERE pe.payment_id = '550e8400-e29b-41d4-a716-446655440000'
ORDER BY pe.seq_no ASC;

-- Get payments with route details
SELECT 
  p.payment_ref,
  p.scheme,
  p.amount,
  p.currency,
  prs.step_no,
  prs.role,
  prs.institution_name,
  prs.bic
FROM payments p
LEFT JOIN payment_route_steps prs ON p.id = prs.payment_id
WHERE p.id = '550e8400-e29b-41d4-a716-446655440000'
ORDER BY prs.step_no;

-- Get party with all identifiers
SELECT 
  p.*,
  json_agg(
    json_build_object(
      'id', pi.id,
      'type', pi.id_type,
      'value', pi.id_value,
      'scheme', pi.scheme
    )
  ) as identifiers
FROM parties p
LEFT JOIN party_identifiers pi ON p.id = pi.party_id
WHERE p.id = '550e8400-e29b-41d4-a716-446655440000'
GROUP BY p.id;

-- ============================================================================
-- TRANSACTION Examples
-- ============================================================================

-- Transaction: Create message with payment and events
BEGIN;

INSERT INTO messages (external_ref, source_system, message_state, total_payments)
VALUES ('BATCH_TXN_001', 'System-A', 'RECEIVED', 1)
RETURNING id INTO message_id_var;

INSERT INTO payments (message_id, payment_ref, scheme, amount, currency, debtor_snapshot, creditor_snapshot)
VALUES (message_id_var, 'PMT-TXN-001', 'FPS', 1000.00, 'GBP', '{"display_name": "Debtor"}'::jsonb, '{"display_name": "Creditor"}'::jsonb)
RETURNING id INTO payment_id_var;

INSERT INTO payment_events (payment_id, from_state, to_state, actor_type)
VALUES (payment_id_var, NULL, 'RECEIVED', 'SYSTEM');

UPDATE messages SET total_payments = 1 WHERE id = message_id_var;

COMMIT;

-- Transaction: Update payment state with event logging
BEGIN;

UPDATE payments 
SET payment_state = 'VALIDATED',
    last_state_changed_at = now(),
    updated_at = now()
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

INSERT INTO payment_events (payment_id, from_state, to_state, actor_type, actor_id, metadata)
VALUES (
  '550e8400-e29b-41d4-a716-446655440000',
  'RECEIVED',
  'VALIDATED',
  'SYSTEM',
  'validation-svc',
  '{"aml": "PASS"}'::jsonb
);

COMMIT;

-- Transaction: Delete payment with cascade cleanup
BEGIN;

DELETE FROM payment_events WHERE payment_id = '550e8400-e29b-41d4-a716-446655440000';
DELETE FROM payment_route_steps WHERE payment_id = '550e8400-e29b-41d4-a716-446655440000';
DELETE FROM payments WHERE id = '550e8400-e29b-41d4-a716-446655440000';

COMMIT;

-- ============================================================================
-- IDEMPOTENCY Patterns
-- ============================================================================

-- Insert message with idempotency check (using ON CONFLICT)
INSERT INTO messages (external_ref, source_system, message_state, total_payments)
VALUES ('BATCH_IDEMPOTENT_001', 'System-A', 'RECEIVED', 0)
ON CONFLICT (external_ref) DO NOTHING;

-- Insert message with idempotency check (using ON CONFLICT UPDATE)
INSERT INTO messages (external_ref, source_system, message_state, total_payments)
VALUES ('BATCH_IDEMPOTENT_002', 'System-A', 'RECEIVED', 0)
ON CONFLICT (external_ref) 
DO UPDATE SET 
  source_system = EXCLUDED.source_system,
  updated_at = now();

-- Insert payment with idempotency check
INSERT INTO payments (message_id, payment_ref, scheme, amount, currency, debtor_snapshot, creditor_snapshot)
VALUES (
  '550e8400-e29b-41d4-a716-446655440000',
  'PMT-IDEMPOTENT-001',
  'FPS',
  1000.00,
  'GBP',
  '{"display_name": "Debtor"}'::jsonb,
  '{"display_name": "Creditor"}'::jsonb
)
ON CONFLICT (payment_ref) DO NOTHING;

-- ============================================================================
-- STATE TRANSITION Examples
-- ============================================================================

-- Transition message state with event logging
BEGIN;

UPDATE messages 
SET message_state = 'VALIDATED',
    last_state_changed_at = now(),
    updated_at = now()
WHERE id = '550e8400-e29b-41d4-a716-446655440000'
  AND message_state = 'RECEIVED';

INSERT INTO message_events (message_id, from_state, to_state, actor_type, actor_id, metadata)
VALUES (
  '550e8400-e29b-41d4-a716-446655440000',
  'RECEIVED',
  'VALIDATED',
  'SYSTEM',
  'validation-svc',
  '{"validation_result": "PASS"}'::jsonb
);

COMMIT;

-- Transition payment state with event logging
BEGIN;

UPDATE payments 
SET payment_state = 'ROUTED',
    last_state_changed_at = now(),
    updated_at = now()
WHERE id = '550e8400-e29b-41d4-a716-446655440000'
  AND payment_state = 'VALIDATED';

INSERT INTO payment_events (payment_id, from_state, to_state, actor_type, actor_id, metadata)
VALUES (
  '550e8400-e29b-41d4-a716-446655440000',
  'VALIDATED',
  'ROUTED',
  'SYSTEM',
  'routing-svc',
  '{"corridor": "FPS:Direct"}'::jsonb
);

COMMIT;

-- ============================================================================
-- ANALYTICS Queries
-- ============================================================================

-- Payment success rate by scheme
SELECT 
  scheme,
  COUNT(*) as total_payments,
  COUNT(CASE WHEN payment_state = 'SETTLED' THEN 1 END) as settled_count,
  COUNT(CASE WHEN payment_state = 'REJECTED' THEN 1 END) as rejected_count,
  ROUND(100.0 * COUNT(CASE WHEN payment_state = 'SETTLED' THEN 1 END) / COUNT(*), 2) as success_rate_pct
FROM payments
GROUP BY scheme
ORDER BY total_payments DESC;

-- Average payment processing time (from RECEIVED to SETTLED)
SELECT 
  p.scheme,
  AVG(EXTRACT(EPOCH FROM (settled_time - received_time))) as avg_seconds
FROM (
  SELECT 
    p.id,
    p.scheme,
    MIN(CASE WHEN pe.to_state = 'RECEIVED' THEN pe.occurred_at END) as received_time,
    MIN(CASE WHEN pe.to_state = 'SETTLED' THEN pe.occurred_at END) as settled_time
  FROM payments p
  JOIN payment_events pe ON p.id = pe.payment_id
  WHERE pe.to_state IN ('RECEIVED', 'SETTLED')
  GROUP BY p.id, p.scheme
  HAVING MIN(CASE WHEN pe.to_state = 'RECEIVED' THEN pe.occurred_at END) IS NOT NULL
    AND MIN(CASE WHEN pe.to_state = 'SETTLED' THEN pe.occurred_at END) IS NOT NULL
) p
GROUP BY p.scheme;

-- Payment volume by day
SELECT 
  DATE(created_at) as payment_date,
  COUNT(*) as payment_count,
  SUM(amount) as total_amount,
  COUNT(DISTINCT currency) as currency_count
FROM payments
WHERE created_at >= now() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY payment_date DESC;

-- Top debtors by payment volume
SELECT 
  p.debtor_id,
  pd.display_name,
  COUNT(*) as payment_count,
  SUM(p.amount) as total_amount
FROM payments p
JOIN parties pd ON p.debtor_id = pd.id
GROUP BY p.debtor_id, pd.display_name
ORDER BY total_amount DESC
LIMIT 10;

-- Route step analysis
SELECT 
  role,
  country_code,
  COUNT(*) as step_count,
  COUNT(DISTINCT payment_id) as payment_count
FROM payment_route_steps
GROUP BY role, country_code
ORDER BY step_count DESC;

