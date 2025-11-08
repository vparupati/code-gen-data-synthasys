-- ============================================================================
-- Advanced PostgreSQL Queries for Payment Processing Model
-- ============================================================================
-- Comprehensive examples of UNION, INTERSECTION, JOINs, subqueries, CTEs,
-- window functions, and analytical queries with descriptive column mappings
-- ============================================================================
--
-- IMPORTANT: This file demonstrates how natural language descriptions map to
-- actual column names. See column_mappings.md for complete mapping reference.
--
-- Example mappings used in this file:
--   "payment amount" → amount
--   "transaction status" → payment_state
--   "sender name" → debtor_snapshot->>'display_name' or via parties join
--   "batch identifier" → external_ref (from messages table)
--   "bank name" → legal_name (from institutions table)
--   "processing duration" → calculated: last_state_changed_at - created_at
-- ============================================================================

-- ============================================================================
-- UNION OPERATIONS
-- ============================================================================

-- UNION: Combine payments from different schemes
-- Natural Language: "Get all payment references from both FPS and SEPA schemes"
-- Maps: payment reference → payment_ref, scheme → scheme
SELECT payment_ref AS transaction_reference, scheme AS payment_method
FROM payments
WHERE scheme = 'FPS'
UNION
SELECT payment_ref, scheme
FROM payments
WHERE scheme = 'SEPA'
ORDER BY transaction_reference;

-- UNION ALL: Combine all payments with duplicates
-- Natural Language: "Get all payment amounts from both settled and rejected transactions"
-- Maps: payment amount → amount, transaction status → payment_state
SELECT amount AS payment_amount, payment_state AS transaction_status
FROM payments
WHERE payment_state = 'SETTLED'
UNION ALL
SELECT amount, payment_state
FROM payments
WHERE payment_state = 'REJECTED'
ORDER BY payment_amount DESC;

-- UNION with different tables: Combine payment and message references
-- Natural Language: "Get all unique identifiers from both payments and messages"
SELECT payment_ref AS identifier, 'payment' AS source_type
FROM payments
WHERE payment_ref IS NOT NULL
UNION
SELECT external_ref, 'message'
FROM messages
WHERE external_ref IS NOT NULL
ORDER BY identifier;

-- UNION with calculated fields
-- Natural Language: "Get processing durations for both payments and messages"
-- Maps: processing duration → calculated from last_state_changed_at - created_at
SELECT 
    payment_ref AS identifier,
    EXTRACT(EPOCH FROM (last_state_changed_at - created_at)) AS processing_duration_seconds,
    'payment' AS entity_type
FROM payments
UNION
SELECT 
    external_ref,
    EXTRACT(EPOCH FROM (last_state_changed_at - created_at)),
    'message'
FROM messages
ORDER BY processing_duration_seconds DESC;

-- ============================================================================
-- INTERSECTION OPERATIONS
-- ============================================================================

-- INTERSECT: Find payments that exist in both GBP and EUR currency lists
-- Natural Language: "Find payment references that appear in both GBP and EUR transactions"
-- Maps: payment reference → payment_ref, currency type → currency
SELECT payment_ref AS transaction_reference
FROM payments
WHERE currency = 'GBP'
INTERSECT
SELECT payment_ref
FROM payments
WHERE currency = 'EUR';

-- INTERSECT with multiple conditions
-- Natural Language: "Find parties that are both debtors and creditors"
-- Maps: party name → display_name, entity type → party_type
SELECT display_name AS party_name
FROM parties
WHERE party_type = 'DEBTOR'
INTERSECT
SELECT display_name
FROM parties
WHERE party_type = 'CREDITOR';

-- INTERSECT using subqueries
-- Natural Language: "Find institutions that have both parties and route steps"
SELECT legal_name AS bank_name
FROM institutions
WHERE id IN (SELECT institution_id FROM parties WHERE institution_id IS NOT NULL)
INTERSECT
SELECT legal_name
FROM institutions
WHERE id IN (SELECT institution_id FROM payment_route_steps WHERE institution_id IS NOT NULL);

-- ============================================================================
-- EXCEPT OPERATIONS
-- ============================================================================

-- EXCEPT: Find payments in one state but not another
-- Natural Language: "Find payment references that are SETTLED but were never REJECTED"
SELECT payment_ref AS transaction_reference
FROM payments
WHERE payment_state = 'SETTLED'
EXCEPT
SELECT payment_ref
FROM payments
WHERE payment_state = 'REJECTED';

-- EXCEPT: Payments without events
-- Natural Language: "Find payments that have no state transition events"
SELECT payment_ref AS transaction_reference
FROM payments
EXCEPT
SELECT DISTINCT p.payment_ref
FROM payments p
JOIN payment_events pe ON p.id = pe.payment_id;

-- ============================================================================
-- INNER JOIN OPERATIONS
-- ============================================================================

-- INNER JOIN: Payments with their message details
-- Natural Language: "Get payment amounts with their message batch identifiers"
-- Maps: payment amount → amount, batch identifier → external_ref
SELECT 
    p.amount AS payment_amount,
    p.payment_ref AS transaction_reference,
    m.external_ref AS batch_identifier,
    m.source_system AS origin_system
FROM payments p
INNER JOIN messages m ON p.message_id = m.id;

-- INNER JOIN: Payments with debtor party information
-- Natural Language: "Get sender names for all payments"
-- Maps: sender name → display_name (via join)
SELECT 
    p.payment_ref AS transaction_reference,
    p.amount AS payment_amount,
    pt.display_name AS sender_name,
    pt.email AS sender_email
FROM payments p
INNER JOIN parties pt ON p.debtor_id = pt.id;

-- INNER JOIN: Multi-table join - Payments with full party and institution info
-- Natural Language: "Get payment details with sender bank name and BIC code"
-- Maps: bank name → legal_name, bank code → bic (via multiple joins)
SELECT 
    p.payment_ref AS transaction_reference,
    p.amount AS payment_amount,
    p.currency AS transaction_currency,
    debtor_party.display_name AS sender_name,
    debtor_inst.legal_name AS sender_bank_name,
    debtor_inst.bic AS sender_bank_code,
    creditor_party.display_name AS receiver_name,
    creditor_inst.legal_name AS receiver_bank_name,
    creditor_inst.bic AS receiver_bank_code
FROM payments p
INNER JOIN parties debtor_party ON p.debtor_id = debtor_party.id
INNER JOIN institutions debtor_inst ON debtor_party.institution_id = debtor_inst.id
INNER JOIN parties creditor_party ON p.creditor_id = creditor_party.id
INNER JOIN institutions creditor_inst ON creditor_party.institution_id = creditor_inst.id;

-- INNER JOIN: Payments with route steps
-- Natural Language: "Get payment routing information with institution details"
SELECT 
    p.payment_ref AS transaction_reference,
    prs.step_no AS routing_step_order,
    prs.role AS routing_role,
    prs.institution_name AS bank_name,
    prs.bic AS bank_code,
    i.legal_name AS institution_legal_name
FROM payments p
INNER JOIN payment_route_steps prs ON p.id = prs.payment_id
LEFT JOIN institutions i ON prs.institution_id = i.id
ORDER BY p.payment_ref, prs.step_no;

-- ============================================================================
-- LEFT JOIN OPERATIONS
-- ============================================================================

-- LEFT JOIN: All payments with optional party information
-- Natural Language: "Get all payments with sender information if available"
-- Maps: sender name → display_name (may be null)
SELECT 
    p.payment_ref AS transaction_reference,
    p.amount AS payment_amount,
    pt.display_name AS sender_name,
    pt.email AS sender_email
FROM payments p
LEFT JOIN parties pt ON p.debtor_id = pt.id;

-- LEFT JOIN: Payments with event counts
-- Natural Language: "Get all payments with their event count"
SELECT 
    p.payment_ref AS transaction_reference,
    p.payment_state AS transaction_status,
    COUNT(pe.id) AS event_count
FROM payments p
LEFT JOIN payment_events pe ON p.id = pe.payment_id
GROUP BY p.id, p.payment_ref, p.payment_state
ORDER BY event_count DESC;

-- LEFT JOIN: Parties with their institution information
-- Natural Language: "Get all parties with their associated bank names"
SELECT 
    pt.display_name AS party_name,
    pt.party_type AS entity_type,
    i.legal_name AS bank_name,
    i.bic AS bank_code
FROM parties pt
LEFT JOIN institutions i ON pt.institution_id = i.id;

-- LEFT JOIN: Messages with payment summaries
-- Natural Language: "Get all message batches with their payment totals"
SELECT 
    m.external_ref AS batch_identifier,
    m.source_system AS origin_system,
    m.total_payments AS declared_payment_count,
    COUNT(p.id) AS actual_payment_count,
    COALESCE(SUM(p.amount), 0) AS total_payment_amount
FROM messages m
LEFT JOIN payments p ON m.id = p.message_id
GROUP BY m.id, m.external_ref, m.source_system, m.total_payments;

-- ============================================================================
-- RIGHT JOIN OPERATIONS
-- ============================================================================

-- RIGHT JOIN: All institutions with their associated parties
-- Natural Language: "Get all financial institutions with their associated parties"
SELECT 
    i.legal_name AS bank_name,
    i.bic AS bank_code,
    pt.display_name AS party_name,
    pt.party_type AS entity_type
FROM parties pt
RIGHT JOIN institutions i ON pt.institution_id = i.id
ORDER BY i.legal_name, pt.display_name;

-- ============================================================================
-- FULL OUTER JOIN OPERATIONS
-- ============================================================================

-- FULL OUTER JOIN: All parties and all payments (matching where possible)
-- Natural Language: "Get all parties and all payments, matching where debtor/creditor relationships exist"
SELECT 
    COALESCE(pt.display_name, 'No Party') AS party_name,
    COALESCE(p.payment_ref, 'No Payment') AS transaction_reference,
    p.amount AS payment_amount
FROM parties pt
FULL OUTER JOIN payments p ON pt.id = p.debtor_id OR pt.id = p.creditor_id;

-- ============================================================================
-- SELF JOIN OPERATIONS
-- ============================================================================

-- SELF JOIN: Find payments with same debtor and creditor
-- Natural Language: "Find payments where sender and receiver are the same party"
SELECT 
    p1.payment_ref AS transaction_reference,
    p1.amount AS payment_amount,
    pt.display_name AS party_name
FROM payments p1
JOIN payments p2 ON p1.debtor_id = p2.creditor_id AND p1.creditor_id = p2.debtor_id
JOIN parties pt ON p1.debtor_id = pt.id
WHERE p1.id != p2.id;

-- SELF JOIN: Find consecutive state transitions
-- Natural Language: "Find payment events where one event's to_state matches next event's from_state"
SELECT 
    pe1.payment_id,
    pe1.to_state AS from_state,
    pe2.to_state AS to_state,
    pe2.occurred_at - pe1.occurred_at AS transition_duration
FROM payment_events pe1
JOIN payment_events pe2 ON pe1.payment_id = pe2.payment_id 
    AND pe1.seq_no + 1 = pe2.seq_no;

-- ============================================================================
-- CROSS JOIN OPERATIONS
-- ============================================================================

-- CROSS JOIN: All combinations of schemes and currencies
-- Natural Language: "Get all possible combinations of payment schemes and currencies"
SELECT 
    s.scheme AS payment_method,
    c.currency AS transaction_currency
FROM (SELECT DISTINCT scheme FROM payments) s
CROSS JOIN (SELECT DISTINCT currency FROM payments) c;

-- ============================================================================
-- SUBQUERIES - SCALAR
-- ============================================================================

-- Scalar subquery: Payment with average amount
-- Natural Language: "Get payments that are above the average payment amount"
-- Maps: payment amount → amount
SELECT 
    payment_ref AS transaction_reference,
    amount AS payment_amount,
    (SELECT AVG(amount) FROM payments) AS average_payment_amount
FROM payments
WHERE amount > (SELECT AVG(amount) FROM payments)
ORDER BY payment_amount DESC;

-- Scalar subquery: Payment with message details
-- Natural Language: "Get payment amounts with their message batch identifiers"
SELECT 
    payment_ref AS transaction_reference,
    amount AS payment_amount,
    (SELECT external_ref FROM messages WHERE id = payments.message_id) AS batch_identifier,
    (SELECT source_system FROM messages WHERE id = payments.message_id) AS origin_system
FROM payments;

-- ============================================================================
-- SUBQUERIES - EXISTS
-- ============================================================================

-- EXISTS: Payments with events
-- Natural Language: "Find payments that have state transition events"
SELECT 
    payment_ref AS transaction_reference,
    amount AS payment_amount,
    payment_state AS transaction_status
FROM payments p
WHERE EXISTS (
    SELECT 1 FROM payment_events pe WHERE pe.payment_id = p.id
);

-- EXISTS: Parties with payments
-- Natural Language: "Find parties that have been involved in payments"
SELECT 
    display_name AS party_name,
    party_type AS entity_type
FROM parties pt
WHERE EXISTS (
    SELECT 1 FROM payments p 
    WHERE p.debtor_id = pt.id OR p.creditor_id = pt.id
);

-- EXISTS: Messages with settled payments
-- Natural Language: "Find message batches that contain settled payments"
SELECT 
    external_ref AS batch_identifier,
    source_system AS origin_system
FROM messages m
WHERE EXISTS (
    SELECT 1 FROM payments p 
    WHERE p.message_id = m.id AND p.payment_state = 'SETTLED'
);

-- ============================================================================
-- SUBQUERIES - IN / NOT IN
-- ============================================================================

-- IN: Payments in specific message batches
-- Natural Language: "Get all payments from specific message batches"
SELECT 
    payment_ref AS transaction_reference,
    amount AS payment_amount
FROM payments
WHERE message_id IN (
    SELECT id FROM messages WHERE external_ref LIKE 'BATCH_2025%'
);

-- NOT IN: Payments without route steps
-- Natural Language: "Find payments that have no routing steps"
SELECT 
    payment_ref AS transaction_reference,
    amount AS payment_amount
FROM payments
WHERE id NOT IN (
    SELECT DISTINCT payment_id FROM payment_route_steps
);

-- IN with multiple columns
-- Natural Language: "Find payments matching specific scheme and currency combinations"
SELECT 
    payment_ref AS transaction_reference,
    scheme AS payment_method,
    currency AS transaction_currency,
    amount AS payment_amount
FROM payments
WHERE (scheme, currency) IN (
    SELECT DISTINCT scheme, currency FROM payments WHERE amount > 1000
);

-- ============================================================================
-- SUBQUERIES - ANY / ALL
-- ============================================================================

-- ANY: Payments greater than any payment in a specific scheme
-- Natural Language: "Find payments that are larger than any FPS payment"
SELECT 
    payment_ref AS transaction_reference,
    amount AS payment_amount,
    scheme AS payment_method
FROM payments
WHERE amount > ANY (
    SELECT amount FROM payments WHERE scheme = 'FPS'
);

-- ALL: Payments greater than all payments in a specific scheme
-- Natural Language: "Find payments that are larger than all FPS payments"
SELECT 
    payment_ref AS transaction_reference,
    amount AS payment_amount,
    scheme AS payment_method
FROM payments
WHERE amount > ALL (
    SELECT amount FROM payments WHERE scheme = 'FPS'
);

-- ============================================================================
-- CORRELATED SUBQUERIES
-- ============================================================================

-- Correlated: Payment with its event count
-- Natural Language: "Get each payment with its number of state transitions"
SELECT 
    payment_ref AS transaction_reference,
    amount AS payment_amount,
    (
        SELECT COUNT(*) 
        FROM payment_events pe 
        WHERE pe.payment_id = payments.id
    ) AS event_count
FROM payments;

-- Correlated: Latest event for each payment
-- Natural Language: "Get the most recent state transition for each payment"
SELECT 
    p.payment_ref AS transaction_reference,
    p.amount AS payment_amount,
    (
        SELECT pe.to_state
        FROM payment_events pe
        WHERE pe.payment_id = p.id
        ORDER BY pe.seq_no DESC
        LIMIT 1
    ) AS latest_state
FROM payments p;

-- Correlated: Payments above average for their scheme
-- Natural Language: "Find payments that are above average for their payment scheme"
SELECT 
    payment_ref AS transaction_reference,
    scheme AS payment_method,
    amount AS payment_amount,
    (
        SELECT AVG(amount) 
        FROM payments p2 
        WHERE p2.scheme = payments.scheme
    ) AS scheme_average
FROM payments
WHERE amount > (
    SELECT AVG(amount) 
    FROM payments p2 
    WHERE p2.scheme = payments.scheme
);

-- ============================================================================
-- COMMON TABLE EXPRESSIONS (CTEs)
-- ============================================================================

-- Simple CTE: Payment statistics by scheme
-- Natural Language: "Calculate payment statistics grouped by payment scheme"
WITH payment_stats AS (
    SELECT 
        scheme AS payment_method,
        COUNT(*) AS transaction_count,
        SUM(amount) AS total_amount,
        AVG(amount) AS average_amount,
        MIN(amount) AS minimum_amount,
        MAX(amount) AS maximum_amount
    FROM payments
    GROUP BY scheme
)
SELECT 
    payment_method,
    transaction_count,
    total_amount,
    ROUND(average_amount::numeric, 2) AS average_amount,
    minimum_amount,
    maximum_amount
FROM payment_stats
ORDER BY total_amount DESC;

-- Multiple CTEs: Complex analysis
-- Natural Language: "Analyze payment processing times by scheme and state"
WITH payment_durations AS (
    SELECT 
        p.id,
        p.scheme AS payment_method,
        p.payment_state AS transaction_status,
        EXTRACT(EPOCH FROM (p.last_state_changed_at - p.created_at)) AS processing_seconds
    FROM payments p
),
scheme_stats AS (
    SELECT 
        payment_method,
        transaction_status,
        AVG(processing_seconds) AS avg_processing_seconds,
        COUNT(*) AS count
    FROM payment_durations
    GROUP BY payment_method, transaction_status
)
SELECT 
    payment_method,
    transaction_status,
    ROUND(avg_processing_seconds::numeric, 2) AS avg_processing_seconds,
    count AS transaction_count
FROM scheme_stats
ORDER BY payment_method, avg_processing_seconds DESC;

-- CTE with JOINs: Payment flow analysis
-- Natural Language: "Analyze payment flow from message to final state"
WITH message_payments AS (
    SELECT 
        m.external_ref AS batch_identifier,
        m.source_system AS origin_system,
        p.payment_ref AS transaction_reference,
        p.amount AS payment_amount,
        p.payment_state AS transaction_status
    FROM messages m
    JOIN payments p ON m.id = p.message_id
),
payment_summary AS (
    SELECT 
        batch_identifier,
        origin_system,
        COUNT(*) AS payment_count,
        SUM(payment_amount) AS total_amount,
        COUNT(CASE WHEN transaction_status = 'SETTLED' THEN 1 END) AS settled_count
    FROM message_payments
    GROUP BY batch_identifier, origin_system
)
SELECT 
    batch_identifier,
    origin_system,
    payment_count,
    total_amount,
    settled_count,
    ROUND(100.0 * settled_count / payment_count, 2) AS settlement_rate_percent
FROM payment_summary
ORDER BY total_amount DESC;

-- Recursive CTE: Payment state transition chain
-- Natural Language: "Build the complete state transition chain for a payment"
WITH RECURSIVE state_chain AS (
    -- Base case: First event
    SELECT 
        payment_id,
        seq_no,
        from_state,
        to_state,
        occurred_at,
        ARRAY[to_state] AS state_path
    FROM payment_events
    WHERE seq_no = 1
    
    UNION ALL
    
    -- Recursive case: Next events
    SELECT 
        pe.payment_id,
        pe.seq_no,
        pe.from_state,
        pe.to_state,
        pe.occurred_at,
        sc.state_path || pe.to_state
    FROM payment_events pe
    JOIN state_chain sc ON pe.payment_id = sc.payment_id 
        AND pe.seq_no = sc.seq_no + 1
)
SELECT 
    p.payment_ref AS transaction_reference,
    sc.state_path AS state_transition_chain,
    array_length(sc.state_path, 1) AS transition_count
FROM state_chain sc
JOIN payments p ON sc.payment_id = p.id
WHERE sc.seq_no = (SELECT MAX(seq_no) FROM payment_events WHERE payment_id = sc.payment_id)
ORDER BY transition_count DESC;

-- ============================================================================
-- WINDOW FUNCTIONS
-- ============================================================================

-- ROW_NUMBER: Rank payments by amount within each scheme
-- Natural Language: "Rank payments by amount within each payment scheme"
SELECT 
    payment_ref AS transaction_reference,
    scheme AS payment_method,
    amount AS payment_amount,
    ROW_NUMBER() OVER (PARTITION BY scheme ORDER BY amount DESC) AS rank_within_scheme
FROM payments
ORDER BY scheme, rank_within_scheme;

-- RANK: Rank payments with ties
-- Natural Language: "Rank all payments by amount, handling ties"
SELECT 
    payment_ref AS transaction_reference,
    amount AS payment_amount,
    RANK() OVER (ORDER BY amount DESC) AS payment_rank
FROM payments;

-- DENSE_RANK: Rank without gaps
-- Natural Language: "Rank payments by amount without gaps in ranking"
SELECT 
    payment_ref AS transaction_reference,
    amount AS payment_amount,
    DENSE_RANK() OVER (ORDER BY amount DESC) AS dense_rank
FROM payments;

-- LAG: Compare with previous payment
-- Natural Language: "Compare each payment amount with the previous payment amount"
SELECT 
    payment_ref AS transaction_reference,
    amount AS payment_amount,
    LAG(amount) OVER (ORDER BY created_at) AS previous_payment_amount,
    amount - LAG(amount) OVER (ORDER BY created_at) AS amount_difference
FROM payments
ORDER BY created_at;

-- LEAD: Compare with next payment
-- Natural Language: "Compare each payment amount with the next payment amount"
SELECT 
    payment_ref AS transaction_reference,
    amount AS payment_amount,
    LEAD(amount) OVER (ORDER BY created_at) AS next_payment_amount
FROM payments
ORDER BY created_at;

-- SUM OVER: Running total
-- Natural Language: "Calculate running total of payment amounts"
SELECT 
    payment_ref AS transaction_reference,
    amount AS payment_amount,
    created_at AS transaction_creation_date,
    SUM(amount) OVER (ORDER BY created_at) AS running_total
FROM payments
ORDER BY created_at;

-- AVG OVER: Moving average
-- Natural Language: "Calculate moving average of payment amounts over last 10 payments"
SELECT 
    payment_ref AS transaction_reference,
    amount AS payment_amount,
    AVG(amount) OVER (
        ORDER BY created_at 
        ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
    ) AS moving_average_10
FROM payments
ORDER BY created_at;

-- PARTITION BY: Statistics within groups
-- Natural Language: "Calculate payment statistics within each currency"
SELECT 
    payment_ref AS transaction_reference,
    currency AS transaction_currency,
    amount AS payment_amount,
    AVG(amount) OVER (PARTITION BY currency) AS avg_for_currency,
    MIN(amount) OVER (PARTITION BY currency) AS min_for_currency,
    MAX(amount) OVER (PARTITION BY currency) AS max_for_currency
FROM payments
ORDER BY currency, amount DESC;

-- Multiple window functions
-- Natural Language: "Get comprehensive ranking and statistics for payments"
SELECT 
    payment_ref AS transaction_reference,
    scheme AS payment_method,
    currency AS transaction_currency,
    amount AS payment_amount,
    ROW_NUMBER() OVER (PARTITION BY scheme ORDER BY amount DESC) AS rank_in_scheme,
    RANK() OVER (ORDER BY amount DESC) AS overall_rank,
    PERCENT_RANK() OVER (ORDER BY amount DESC) AS percentile_rank,
    SUM(amount) OVER (PARTITION BY scheme) AS total_for_scheme
FROM payments
ORDER BY scheme, amount DESC;

-- ============================================================================
-- ANALYTICAL QUERIES - GROUP BY
-- ============================================================================

-- Basic GROUP BY: Payment count by scheme
-- Natural Language: "Count transactions grouped by payment scheme"
SELECT 
    scheme AS payment_method,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_payment_amount
FROM payments
GROUP BY scheme
ORDER BY total_payment_amount DESC;

-- GROUP BY with HAVING: Filter groups
-- Natural Language: "Find payment schemes with average amount above 1000"
SELECT 
    scheme AS payment_method,
    COUNT(*) AS transaction_count,
    AVG(amount) AS average_payment_amount
FROM payments
GROUP BY scheme
HAVING AVG(amount) > 1000
ORDER BY average_payment_amount DESC;

-- GROUP BY multiple columns
-- Natural Language: "Analyze payments by scheme and currency combination"
SELECT 
    scheme AS payment_method,
    currency AS transaction_currency,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount,
    AVG(amount) AS average_amount
FROM payments
GROUP BY scheme, currency
ORDER BY scheme, total_amount DESC;

-- GROUP BY ROLLUP: Hierarchical aggregation
-- Natural Language: "Get payment totals with subtotals by scheme and currency"
SELECT 
    scheme AS payment_method,
    currency AS transaction_currency,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM payments
GROUP BY ROLLUP(scheme, currency)
ORDER BY scheme NULLS LAST, currency NULLS LAST;

-- GROUP BY CUBE: All combinations
-- Natural Language: "Get payment statistics for all combinations of scheme and currency"
SELECT 
    scheme AS payment_method,
    currency AS transaction_currency,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM payments
GROUP BY CUBE(scheme, currency)
ORDER BY scheme NULLS LAST, currency NULLS LAST;

-- GROUPING SETS: Specific combinations
-- Natural Language: "Get payment totals by scheme, by currency, and overall"
SELECT 
    scheme AS payment_method,
    currency AS transaction_currency,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM payments
GROUP BY GROUPING SETS (
    (scheme),
    (currency),
    ()
)
ORDER BY scheme NULLS LAST, currency NULLS LAST;

-- ============================================================================
-- ANALYTICAL QUERIES - TIME SERIES
-- ============================================================================

-- Payments by day
-- Natural Language: "Get daily payment volume and totals"
SELECT 
    DATE(created_at) AS payment_date,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_payment_amount,
    AVG(amount) AS average_payment_amount
FROM payments
GROUP BY DATE(created_at)
ORDER BY payment_date DESC;

-- Payments by hour
-- Natural Language: "Analyze payment volume by hour of day"
SELECT 
    EXTRACT(HOUR FROM created_at) AS hour_of_day,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_payment_amount
FROM payments
GROUP BY EXTRACT(HOUR FROM created_at)
ORDER BY hour_of_day;

-- Monthly trends
-- Natural Language: "Get monthly payment statistics"
SELECT 
    DATE_TRUNC('month', created_at) AS payment_month,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_payment_amount,
    COUNT(DISTINCT scheme) AS scheme_count
FROM payments
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY payment_month DESC;

-- ============================================================================
-- ANALYTICAL QUERIES - STATE TRANSITIONS
-- ============================================================================

-- State transition analysis
-- Natural Language: "Analyze state transitions: count transitions from each state to each state"
SELECT 
    from_state AS source_state,
    to_state AS target_state,
    COUNT(*) AS transition_count,
    AVG(EXTRACT(EPOCH FROM (occurred_at - LAG(occurred_at) OVER (PARTITION BY payment_id ORDER BY seq_no)))) AS avg_time_between_transitions
FROM payment_events
GROUP BY from_state, to_state
ORDER BY transition_count DESC;

-- Payment lifecycle analysis
-- Natural Language: "Calculate average time spent in each payment state"
WITH state_durations AS (
    SELECT 
        payment_id,
        from_state,
        to_state,
        occurred_at,
        LEAD(occurred_at) OVER (PARTITION BY payment_id ORDER BY seq_no) - occurred_at AS duration_in_state
    FROM payment_events
)
SELECT 
    from_state AS state_name,
    COUNT(*) AS state_occurrences,
    AVG(EXTRACT(EPOCH FROM duration_in_state)) AS avg_seconds_in_state,
    MIN(EXTRACT(EPOCH FROM duration_in_state)) AS min_seconds_in_state,
    MAX(EXTRACT(EPOCH FROM duration_in_state)) AS max_seconds_in_state
FROM state_durations
WHERE duration_in_state IS NOT NULL
GROUP BY from_state
ORDER BY avg_seconds_in_state DESC;

-- ============================================================================
-- ANALYTICAL QUERIES - ROUTING ANALYSIS
-- ============================================================================

-- Route step analysis
-- Natural Language: "Analyze routing patterns: count steps by role and country"
SELECT 
    role AS routing_role,
    country_code AS institution_country,
    COUNT(*) AS step_count,
    COUNT(DISTINCT payment_id) AS payment_count
FROM payment_route_steps
GROUP BY role, country_code
ORDER BY step_count DESC;

-- Average route length by scheme
-- Natural Language: "Calculate average number of routing steps per payment scheme"
SELECT 
    p.scheme AS payment_method,
    AVG(step_counts.step_count) AS avg_route_steps,
    MAX(step_counts.step_count) AS max_route_steps,
    MIN(step_counts.step_count) AS min_route_steps
FROM payments p
JOIN (
    SELECT payment_id, COUNT(*) AS step_count
    FROM payment_route_steps
    GROUP BY payment_id
) step_counts ON p.id = step_counts.payment_id
GROUP BY p.scheme
ORDER BY avg_route_steps DESC;

-- ============================================================================
-- COMPLEX FILTERING - CASE STATEMENTS
-- ============================================================================

-- CASE: Categorize payment amounts
-- Natural Language: "Categorize payments by amount ranges"
SELECT 
    payment_ref AS transaction_reference,
    amount AS payment_amount,
    CASE
        WHEN amount < 100 THEN 'Small'
        WHEN amount < 1000 THEN 'Medium'
        WHEN amount < 10000 THEN 'Large'
        ELSE 'Very Large'
    END AS payment_category
FROM payments
ORDER BY amount DESC;

-- CASE: Payment status description
-- Natural Language: "Get human-readable payment status descriptions"
SELECT 
    payment_ref AS transaction_reference,
    payment_state AS transaction_status,
    CASE payment_state
        WHEN 'RECEIVED' THEN 'Payment Received'
        WHEN 'VALIDATED' THEN 'Payment Validated'
        WHEN 'SETTLED' THEN 'Payment Settled'
        WHEN 'REJECTED' THEN 'Payment Rejected'
        WHEN 'FAILED' THEN 'Payment Failed'
        ELSE 'Unknown Status'
    END AS status_description
FROM payments;

-- CASE with aggregation
-- Natural Language: "Count payments by status category"
SELECT 
    CASE 
        WHEN payment_state IN ('SETTLED', 'SENT_TO_SCHEME') THEN 'Success'
        WHEN payment_state IN ('REJECTED', 'FAILED') THEN 'Failure'
        ELSE 'In Progress'
    END AS status_category,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM payments
GROUP BY status_category;

-- ============================================================================
-- COMPLEX FILTERING - COALESCE
-- ============================================================================

-- COALESCE: Use snapshot or joined data
-- Natural Language: "Get sender name, preferring snapshot data over joined party data"
SELECT 
    p.payment_ref AS transaction_reference,
    COALESCE(
        p.debtor_snapshot->>'display_name',
        pt.display_name,
        'Unknown Sender'
    ) AS sender_name
FROM payments p
LEFT JOIN parties pt ON p.debtor_id = pt.id;

-- COALESCE: Default values
-- Natural Language: "Get payment references with default for missing values"
SELECT 
    COALESCE(payment_ref, 'REF-' || id::text) AS transaction_reference,
    amount AS payment_amount
FROM payments;

-- ============================================================================
-- COMPLEX ANALYTICAL QUERIES
-- ============================================================================

-- Payment success rate by scheme
-- Natural Language: "Calculate payment success rate grouped by payment scheme"
SELECT 
    scheme AS payment_method,
    COUNT(*) AS total_transactions,
    COUNT(CASE WHEN payment_state = 'SETTLED' THEN 1 END) AS settled_count,
    COUNT(CASE WHEN payment_state = 'REJECTED' THEN 1 END) AS rejected_count,
    ROUND(100.0 * COUNT(CASE WHEN payment_state = 'SETTLED' THEN 1 END) / COUNT(*), 2) AS success_rate_percent
FROM payments
GROUP BY scheme
ORDER BY success_rate_percent DESC;

-- Top debtors by volume
-- Natural Language: "Find top 10 senders by total payment volume"
SELECT 
    pt.display_name AS sender_name,
    COUNT(*) AS transaction_count,
    SUM(p.amount) AS total_payment_amount,
    AVG(p.amount) AS average_payment_amount
FROM payments p
JOIN parties pt ON p.debtor_id = pt.id
GROUP BY pt.id, pt.display_name
ORDER BY total_payment_amount DESC
LIMIT 10;

-- Payment processing time analysis
-- Natural Language: "Analyze payment processing times from creation to settlement"
WITH processing_times AS (
    SELECT 
        p.payment_ref AS transaction_reference,
        p.scheme AS payment_method,
        p.created_at AS creation_time,
        MAX(CASE WHEN pe.to_state = 'SETTLED' THEN pe.occurred_at END) AS settlement_time
    FROM payments p
    LEFT JOIN payment_events pe ON p.id = pe.payment_id
    GROUP BY p.id, p.payment_ref, p.scheme, p.created_at
    HAVING MAX(CASE WHEN pe.to_state = 'SETTLED' THEN pe.occurred_at END) IS NOT NULL
)
SELECT 
    payment_method,
    COUNT(*) AS settled_count,
    AVG(EXTRACT(EPOCH FROM (settlement_time - creation_time))) AS avg_processing_seconds,
    MIN(EXTRACT(EPOCH FROM (settlement_time - creation_time))) AS min_processing_seconds,
    MAX(EXTRACT(EPOCH FROM (settlement_time - creation_time))) AS max_processing_seconds
FROM processing_times
GROUP BY payment_method
ORDER BY avg_processing_seconds;

-- Message batch analysis
-- Natural Language: "Analyze message batches: count, totals, and success rates"
SELECT 
    m.external_ref AS batch_identifier,
    m.source_system AS origin_system,
    m.total_payments AS declared_count,
    COUNT(p.id) AS actual_payment_count,
    SUM(p.amount) AS total_batch_amount,
    COUNT(CASE WHEN p.payment_state = 'SETTLED' THEN 1 END) AS settled_count,
    ROUND(100.0 * COUNT(CASE WHEN p.payment_state = 'SETTLED' THEN 1 END) / NULLIF(COUNT(p.id), 0), 2) AS batch_success_rate
FROM messages m
LEFT JOIN payments p ON m.id = p.message_id
GROUP BY m.id, m.external_ref, m.source_system, m.total_payments
ORDER BY total_batch_amount DESC NULLS LAST;

-- Institution routing analysis
-- Natural Language: "Analyze which institutions are used most in payment routing"
SELECT 
    i.legal_name AS bank_name,
    i.bic AS bank_code,
    i.country_code AS institution_country,
    COUNT(prs.id) AS routing_occurrences,
    COUNT(DISTINCT prs.payment_id) AS unique_payment_count,
    COUNT(DISTINCT prs.role) AS roles_played
FROM institutions i
JOIN payment_route_steps prs ON i.id = prs.institution_id
GROUP BY i.id, i.legal_name, i.bic, i.country_code
ORDER BY routing_occurrences DESC;

-- ============================================================================
-- NATURAL LANGUAGE TO COLUMN MAPPING EXAMPLES
-- ============================================================================
-- These examples demonstrate how natural language descriptions are mapped
-- to actual database column names. This helps train SLMs to understand
-- that queries can be expressed in multiple ways.
-- ============================================================================

-- Example 1: Simple field access with natural language
-- Natural Language: "Show me the money transferred for each transaction"
-- Maps: "money transferred" → amount
SELECT 
    payment_ref AS transaction_reference,
    amount AS money_transferred
FROM payments;

-- Example 2: Status field with alternative descriptions
-- Natural Language: "Get the current status of all payments"
-- Maps: "current status" → payment_state, "transaction status" → payment_state
SELECT 
    payment_ref AS transaction_reference,
    payment_state AS current_status,
    payment_state AS transaction_status
FROM payments;

-- Example 3: Nested JSONB field access
-- Natural Language: "Get the name of the person sending money"
-- Maps: "name of person sending money" → debtor_snapshot->>'display_name'
SELECT 
    payment_ref AS transaction_reference,
    debtor_snapshot->>'display_name' AS sender_name,
    debtor_snapshot->>'display_name' AS name_of_person_sending_money
FROM payments;

-- Example 4: Calculated field from natural language
-- Natural Language: "How long did it take to process each payment?"
-- Maps: "processing time" → calculated: last_state_changed_at - created_at
SELECT 
    payment_ref AS transaction_reference,
    EXTRACT(EPOCH FROM (last_state_changed_at - created_at)) AS processing_time_seconds,
    EXTRACT(EPOCH FROM (last_state_changed_at - created_at)) AS how_long_to_process
FROM payments;

-- Example 5: Join required for natural language description
-- Natural Language: "What is the name of the bank that sent the payment?"
-- Maps: "bank that sent payment" → requires join: parties -> institutions -> legal_name
SELECT 
    p.payment_ref AS transaction_reference,
    i.legal_name AS bank_that_sent_payment,
    i.legal_name AS sender_bank_name
FROM payments p
JOIN parties pt ON p.debtor_id = pt.id
JOIN institutions i ON pt.institution_id = i.id;

-- Example 6: Multiple natural language descriptions for same field
-- Natural Language: "Get payment currency, transaction currency, and currency type"
-- Maps: All three → currency column
SELECT 
    payment_ref AS transaction_reference,
    currency AS payment_currency,
    currency AS transaction_currency,
    currency AS currency_type
FROM payments;

-- Example 7: Natural language with aggregation
-- Natural Language: "What is the total money moved through each payment scheme?"
-- Maps: "money moved" → amount, "payment scheme" → scheme
SELECT 
    scheme AS payment_scheme,
    SUM(amount) AS total_money_moved,
    SUM(amount) AS total_amount
FROM payments
GROUP BY scheme;

-- Example 8: Natural language describing a relationship
-- Natural Language: "Show payments with their message batch information"
-- Maps: "message batch information" → requires join to messages table
SELECT 
    p.payment_ref AS transaction_reference,
    p.amount AS payment_amount,
    m.external_ref AS message_batch_identifier,
    m.source_system AS message_batch_source
FROM payments p
JOIN messages m ON p.message_id = m.id;

-- Example 9: Natural language with time-based calculations
-- Natural Language: "When was each payment created and how many days ago was that?"
-- Maps: "when created" → created_at, "days ago" → calculated
SELECT 
    payment_ref AS transaction_reference,
    created_at AS when_created,
    CURRENT_DATE - DATE(created_at) AS days_ago
FROM payments;

-- Example 10: Natural language describing complex relationships
-- Natural Language: "Show the complete payment flow: sender bank, receiver bank, and routing method"
-- Maps: Requires multiple joins and JSONB access
SELECT 
    p.payment_ref AS transaction_reference,
    debtor_inst.legal_name AS sender_bank,
    creditor_inst.legal_name AS receiver_bank,
    p.route_summary->>'method' AS routing_method
FROM payments p
LEFT JOIN parties debtor_party ON p.debtor_id = debtor_party.id
LEFT JOIN institutions debtor_inst ON debtor_party.institution_id = debtor_inst.id
LEFT JOIN parties creditor_party ON p.creditor_id = creditor_party.id
LEFT JOIN institutions creditor_inst ON creditor_party.institution_id = creditor_inst.id;

