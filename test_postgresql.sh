#!/bin/bash
# ============================================================================
# PostgreSQL CRUD Operations Test Script
# ============================================================================
# This script tests basic CRUD operations on PostgreSQL
# ============================================================================

set -e

PGHOST=localhost
PGPORT=5433
PGUSER=payment_user
PGPASSWORD=payment_pass
PGDATABASE=payment_db

export PGPASSWORD

echo "============================================================================"
echo "PostgreSQL CRUD Operations Test"
echo "============================================================================"
echo ""

# Test 1: CREATE - Insert institution
echo "Test 1: CREATE - Insert institution"
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE <<EOF
INSERT INTO institutions (legal_name, bic, country_code)
VALUES ('Test Bank Ltd', 'TESTGB22XXX', 'GB')
RETURNING id, legal_name;
EOF
echo "✓ Test 1 passed"
echo ""

# Test 2: READ - Get institutions
echo "Test 2: READ - Get all institutions"
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE <<EOF
SELECT id, legal_name, bic, country_code FROM institutions ORDER BY created_at DESC LIMIT 5;
EOF
echo "✓ Test 2 passed"
echo ""

# Test 3: CREATE - Insert party
echo "Test 3: CREATE - Insert party"
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE <<EOF
INSERT INTO parties (party_type, display_name, email)
VALUES ('DEBTOR', 'Test Company', 'test@example.com')
RETURNING id, display_name, party_type;
EOF
echo "✓ Test 3 passed"
echo ""

# Test 4: READ - Get parties with join
echo "Test 4: READ - Get parties with institution join"
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE <<EOF
SELECT p.id, p.display_name, p.party_type, i.legal_name as institution_name
FROM parties p
LEFT JOIN institutions i ON p.institution_id = i.id
ORDER BY p.created_at DESC LIMIT 5;
EOF
echo "✓ Test 4 passed"
echo ""

# Test 5: CREATE - Insert message
echo "Test 5: CREATE - Insert message"
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE <<EOF
INSERT INTO messages (external_ref, source_system, message_state, attributes)
VALUES ('TEST_MSG_001', 'TestSystem', 'RECEIVED', '{"test": true}'::jsonb)
RETURNING id, external_ref, message_state;
EOF
echo "✓ Test 5 passed"
echo ""

# Test 6: READ - Query JSONB attributes
echo "Test 6: READ - Query messages with JSONB filter"
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE <<EOF
SELECT id, external_ref, attributes->>'test' as test_flag
FROM messages
WHERE attributes @> '{"test": true}'::jsonb
ORDER BY created_at DESC LIMIT 5;
EOF
echo "✓ Test 6 passed"
echo ""

# Test 7: CREATE - Insert payment
echo "Test 7: CREATE - Insert payment"
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE <<EOF
DO \$\$
DECLARE
    msg_id UUID;
    pay_id UUID;
BEGIN
    SELECT id INTO msg_id FROM messages WHERE external_ref = 'TEST_MSG_001' LIMIT 1;
    
    INSERT INTO payments (
        message_id, payment_ref, scheme, amount, currency,
        debtor_snapshot, creditor_snapshot
    )
    VALUES (
        msg_id,
        'PMT-TEST-001',
        'FPS',
        1000.00,
        'GBP',
        '{"display_name": "Test Debtor"}'::jsonb,
        '{"display_name": "Test Creditor"}'::jsonb
    )
    RETURNING id INTO pay_id;
    
    RAISE NOTICE 'Payment created with ID: %', pay_id;
END \$\$;
EOF
echo "✓ Test 7 passed"
echo ""

# Test 8: READ - Get payments with message details
echo "Test 8: READ - Get payments with message join"
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE <<EOF
SELECT 
    p.payment_ref,
    p.scheme,
    p.amount,
    p.currency,
    p.payment_state,
    m.external_ref as message_ref
FROM payments p
JOIN messages m ON p.message_id = m.id
ORDER BY p.created_at DESC LIMIT 5;
EOF
echo "✓ Test 8 passed"
echo ""

# Test 9: UPDATE - Update payment state
echo "Test 9: UPDATE - Update payment state"
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE <<EOF
UPDATE payments
SET payment_state = 'VALIDATED',
    last_state_changed_at = now(),
    updated_at = now()
WHERE payment_ref = 'PMT-TEST-001'
RETURNING payment_ref, payment_state, last_state_changed_at;
EOF
echo "✓ Test 9 passed"
echo ""

# Test 10: CREATE - Insert payment event
echo "Test 10: CREATE - Insert payment event"
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE <<EOF
INSERT INTO payment_events (payment_id, from_state, to_state, actor_type, actor_id, metadata)
SELECT 
    id,
    'RECEIVED',
    'VALIDATED',
    'SYSTEM',
    'test-script',
    '{"test": true}'::jsonb
FROM payments
WHERE payment_ref = 'PMT-TEST-001'
RETURNING id, seq_no, from_state, to_state;
EOF
echo "✓ Test 10 passed"
echo ""

# Test 11: READ - Get payment events
echo "Test 11: READ - Get payment event history"
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE <<EOF
SELECT 
    pe.seq_no,
    pe.from_state,
    pe.to_state,
    pe.occurred_at,
    p.payment_ref
FROM payment_events pe
JOIN payments p ON pe.payment_id = p.id
WHERE p.payment_ref = 'PMT-TEST-001'
ORDER BY pe.seq_no ASC;
EOF
echo "✓ Test 11 passed"
echo ""

# Test 12: READ - Analytics query (count by state)
echo "Test 12: READ - Analytics (payment count by state)"
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE <<EOF
SELECT 
    payment_state,
    COUNT(*) as count,
    SUM(amount) as total_amount
FROM payments
GROUP BY payment_state
ORDER BY count DESC;
EOF
echo "✓ Test 12 passed"
echo ""

# Test 13: DELETE - Cleanup test data
echo "Test 13: DELETE - Cleanup test data"
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE <<EOF
DELETE FROM payment_events WHERE payment_id IN (
    SELECT id FROM payments WHERE payment_ref = 'PMT-TEST-001'
);
DELETE FROM payments WHERE payment_ref = 'PMT-TEST-001';
DELETE FROM messages WHERE external_ref = 'TEST_MSG_001';
DELETE FROM parties WHERE display_name = 'Test Company';
DELETE FROM institutions WHERE legal_name = 'Test Bank Ltd';
EOF
echo "✓ Test 13 passed"
echo ""

echo "============================================================================"
echo "All PostgreSQL CRUD tests completed successfully!"
echo "============================================================================"

unset PGPASSWORD

