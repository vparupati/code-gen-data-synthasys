# Column and Field Mappings - Natural Language to Database Schema

This document maps natural language descriptions to actual column/field names in both PostgreSQL and MongoDB schemas. This enables text-to-code generation to understand queries through descriptive language rather than requiring direct knowledge of column names.

## Purpose

When training an SLM for text-to-SQL/NoSQL conversion, the model needs to understand that:
- "payment amount" refers to the `amount` column
- "transaction status" refers to `payment_state` or `current_state`
- "sender bank name" requires joining tables or looking up embedded documents

This mapping file provides the bridge between natural language and actual schema.

---

## PostgreSQL Mappings

### Payments Table (`payments`)

| Natural Language Description | Actual Column Name | Data Type | Notes |
|------------------------------|-------------------|-----------|-------|
| payment amount | `amount` | NUMERIC(19,4) | The monetary value of the transaction |
| transaction amount | `amount` | NUMERIC(19,4) | Alternative description |
| payment value | `amount` | NUMERIC(19,4) | Alternative description |
| money transferred | `amount` | NUMERIC(19,4) | Alternative description |
| transaction status | `payment_state` | payment_state ENUM | Current state: RECEIVED, VALIDATED, SETTLED, etc. |
| payment status | `payment_state` | payment_state ENUM | Alternative description |
| transaction state | `payment_state` | payment_state ENUM | Alternative description |
| payment currency | `currency` | currency_code ENUM | Currency code: GBP, USD, EUR, etc. |
| transaction currency | `currency` | currency_code ENUM | Alternative description |
| currency type | `currency` | currency_code ENUM | Alternative description |
| payment reference | `payment_ref` | TEXT | Unique payment identifier |
| transaction reference | `payment_ref` | TEXT | Alternative description |
| payment ID | `id` | UUID | Primary key |
| transaction ID | `id` | UUID | Alternative description |
| payment scheme | `scheme` | TEXT | Payment scheme: FPS, SEPA, etc. |
| transaction scheme | `scheme` | TEXT | Alternative description |
| payment method | `scheme` | TEXT | Alternative description |
| last state change time | `last_state_changed_at` | TIMESTAMPTZ | When status last changed |
| status change timestamp | `last_state_changed_at` | TIMESTAMPTZ | Alternative description |
| instruction time | `instructed_on` | TIMESTAMPTZ | When payment was instructed |
| payment instruction date | `instructed_on` | TIMESTAMPTZ | Alternative description |
| creation time | `created_at` | TIMESTAMPTZ | When record was created |
| transaction creation date | `created_at` | TIMESTAMPTZ | Alternative description |
| update timestamp | `updated_at` | TIMESTAMPTZ | Last update time |
| sender information | `debtor_snapshot` | JSONB | Snapshot of debtor details at payment time |
| sender details | `debtor_snapshot` | JSONB | Alternative description |
| payer information | `debtor_snapshot` | JSONB | Alternative description |
| sender name | `debtor_snapshot->>'display_name'` | TEXT (from JSONB) | Debtor's display name |
| payer name | `debtor_snapshot->>'display_name'` | TEXT (from JSONB) | Alternative description |
| sender account identifiers | `debtor_snapshot->'identifiers'` | JSONB array | Debtor's account numbers, IBANs, etc. |
| receiver information | `creditor_snapshot` | JSONB | Snapshot of creditor details |
| receiver details | `creditor_snapshot` | JSONB | Alternative description |
| payee information | `creditor_snapshot` | JSONB | Alternative description |
| receiver name | `creditor_snapshot->>'display_name'` | TEXT (from JSONB) | Creditor's display name |
| payee name | `creditor_snapshot->>'display_name'` | TEXT (from JSONB) | Alternative description |
| receiver account identifiers | `creditor_snapshot->'identifiers'` | JSONB array | Creditor's account numbers, IBANs, etc. |
| routing summary | `route_summary` | JSONB | Summary of payment routing |
| routing method | `route_summary->>'method'` | TEXT (from JSONB) | Routing method: DIRECT, INDIRECT, etc. |
| payment attributes | `attributes` | JSONB | Additional payment metadata |
| transaction metadata | `attributes` | JSONB | Alternative description |
| processing duration | `last_state_changed_at - created_at` | INTERVAL | Calculated: time from creation to last state change |
| processing time | `last_state_changed_at - created_at` | INTERVAL | Alternative description |
| time to process | `last_state_changed_at - created_at` | INTERVAL | Alternative description |

### Messages Table (`messages`)

| Natural Language Description | Actual Column Name | Data Type | Notes |
|------------------------------|-------------------|-----------|-------|
| message batch identifier | `external_ref` | TEXT | External reference for the message batch |
| batch reference | `external_ref` | TEXT | Alternative description |
| message ID | `id` | UUID | Primary key |
| batch ID | `id` | UUID | Alternative description |
| source system | `source_system` | TEXT | System that sent the message |
| origin system | `source_system` | TEXT | Alternative description |
| message status | `message_state` | message_state ENUM | Current state: RECEIVED, VALIDATED, SETTLED, etc. |
| batch status | `message_state` | message_state ENUM | Alternative description |
| total payment count | `total_payments` | INT | Number of payments in the batch |
| number of transactions | `total_payments` | INT | Alternative description |
| received timestamp | `received_at` | TIMESTAMPTZ | When message was received |
| message received date | `received_at` | TIMESTAMPTZ | Alternative description |
| last state change | `last_state_changed_at` | TIMESTAMPTZ | When status last changed |
| message attributes | `attributes` | JSONB | Additional message metadata |
| batch attributes | `attributes` | JSONB | Alternative description |

### Parties Table (`parties`)

| Natural Language Description | Actual Column Name | Data Type | Notes |
|------------------------------|-------------------|-----------|-------|
| party name | `display_name` | TEXT | Display name of the party |
| entity name | `display_name` | TEXT | Alternative description |
| organization name | `display_name` | TEXT | Alternative description |
| party type | `party_type` | party_type ENUM | DEBTOR, CREDITOR, INTERMEDIARY, BOTH |
| entity type | `party_type` | party_type ENUM | Alternative description |
| party ID | `id` | UUID | Primary key |
| entity ID | `id` | UUID | Alternative description |
| contact email | `email` | TEXT | Email address |
| email address | `email` | TEXT | Alternative description |
| phone number | `phone` | TEXT | Phone number |
| contact phone | `phone` | TEXT | Alternative description |
| associated institution | `institution_id` | UUID | Foreign key to institutions table |
| bank ID | `institution_id` | UUID | Alternative description (requires join) |
| financial institution ID | `institution_id` | UUID | Alternative description (requires join) |

### Institutions Table (`institutions`)

| Natural Language Description | Actual Column Name | Data Type | Notes |
|------------------------------|-------------------|-----------|-------|
| bank name | `legal_name` | TEXT | Legal name of the institution |
| financial institution name | `legal_name` | TEXT | Alternative description |
| institution name | `legal_name` | TEXT | Alternative description |
| bank code | `bic` | TEXT | Bank Identifier Code |
| BIC code | `bic` | TEXT | Alternative description |
| SWIFT code | `bic` | TEXT | Alternative description |
| legal entity identifier | `lei` | TEXT | Legal Entity Identifier |
| LEI code | `lei` | TEXT | Alternative description |
| country code | `country_code` | CHAR(2) | ISO country code |
| institution country | `country_code` | CHAR(2) | Alternative description |
| bank country | `country_code` | CHAR(2) | Alternative description |

### Payment Events Table (`payment_events`)

| Natural Language Description | Actual Column Name | Data Type | Notes |
|------------------------------|-------------------|-----------|-------|
| event sequence number | `seq_no` | BIGSERIAL | Sequence number of the event |
| event order | `seq_no` | BIGSERIAL | Alternative description |
| previous state | `from_state` | payment_state ENUM | State before transition |
| source state | `from_state` | payment_state ENUM | Alternative description |
| new state | `to_state` | payment_state ENUM | State after transition |
| target state | `to_state` | payment_state ENUM | Alternative description |
| transition reason code | `reason_code` | TEXT | Code explaining the transition |
| rejection code | `reason_code` | TEXT | Alternative description (when to_state is REJECTED) |
| reason description | `reason_text` | TEXT | Human-readable reason |
| actor type | `actor_type` | TEXT | Who/what performed the action: SYSTEM, USER, etc. |
| performed by | `actor_type` | TEXT | Alternative description |
| actor identifier | `actor_id` | TEXT | Specific identifier of the actor |
| service name | `actor_id` | TEXT | Alternative description (when actor_type is SYSTEM) |
| event timestamp | `occurred_at` | TIMESTAMPTZ | When the event occurred |
| transition time | `occurred_at` | TIMESTAMPTZ | Alternative description |
| event metadata | `metadata` | JSONB | Additional event information |

### Payment Route Steps Table (`payment_route_steps`)

| Natural Language Description | Actual Column Name | Data Type | Notes |
|------------------------------|-------------------|-----------|-------|
| step number | `step_no` | INT | Order of the routing step |
| routing step order | `step_no` | INT | Alternative description |
| step role | `role` | route_role ENUM | SENDER_BANK, INTERMEDIARY, RECEIVER_BANK, etc. |
| routing role | `role` | route_role ENUM | Alternative description |
| institution name | `institution_name` | TEXT | Name of the institution at this step |
| bank name | `institution_name` | TEXT | Alternative description |
| step BIC code | `bic` | TEXT | BIC of the institution at this step |
| step LEI code | `lei` | TEXT | LEI of the institution at this step |
| step country | `country_code` | CHAR(2) | Country code of the institution |
| step metadata | `metadata` | JSONB | Additional routing step information |

---

## MongoDB Mappings

### Payments Collection (`payments`)

| Natural Language Description | Actual Field Path | Data Type | Notes |
|------------------------------|------------------|-----------|-------|
| payment amount | `amount` | NumberDecimal | The monetary value of the transaction |
| transaction amount | `amount` | NumberDecimal | Alternative description |
| payment value | `amount` | NumberDecimal | Alternative description |
| money transferred | `amount` | NumberDecimal | Alternative description |
| transaction status | `current_state` | String | Current state: RECEIVED, VALIDATED, SETTLED, etc. |
| payment status | `current_state` | String | Alternative description |
| transaction state | `current_state` | String | Alternative description |
| payment currency | `currency` | String | Currency code: GBP, USD, EUR, etc. |
| transaction currency | `currency` | String | Alternative description |
| currency type | `currency` | String | Alternative description |
| payment reference | `payment_ref` | String | Unique payment identifier |
| transaction reference | `payment_ref` | String | Alternative description |
| payment ID | `_id` | ObjectId | Primary key |
| transaction ID | `_id` | ObjectId | Alternative description |
| payment scheme | `scheme` | String | Payment scheme: FPS, SEPA, etc. |
| transaction scheme | `scheme` | String | Alternative description |
| payment method | `scheme` | String | Alternative description |
| last state change time | `last_state_changed_at` | Date | When status last changed |
| status change timestamp | `last_state_changed_at` | Date | Alternative description |
| instruction time | `instructed_on` | Date | When payment was instructed |
| payment instruction date | `instructed_on` | Date | Alternative description |
| creation time | `created_at` | Date | When record was created |
| transaction creation date | `created_at` | Date | Alternative description |
| update timestamp | `updated_at` | Date | Last update time |
| sender information | `debtor_snapshot` | Object | Snapshot of debtor details at payment time |
| sender details | `debtor_snapshot` | Object | Alternative description |
| payer information | `debtor_snapshot` | Object | Alternative description |
| sender name | `debtor_snapshot.display_name` | String | Debtor's display name |
| payer name | `debtor_snapshot.display_name` | String | Alternative description |
| sender account identifiers | `debtor_snapshot.identifiers` | Array | Debtor's account numbers, IBANs, etc. |
| receiver information | `creditor_snapshot` | Object | Snapshot of creditor details |
| receiver details | `creditor_snapshot` | Object | Alternative description |
| payee information | `creditor_snapshot` | Object | Alternative description |
| receiver name | `creditor_snapshot.display_name` | String | Creditor's display name |
| payee name | `creditor_snapshot.display_name` | String | Alternative description |
| receiver account identifiers | `creditor_snapshot.identifiers` | Array | Creditor's account numbers, IBANs, etc. |
| routing summary | `route_summary` | Object | Summary of payment routing |
| routing method | `route_summary.method` | String | Routing method: DIRECT, INDIRECT, etc. |
| payment attributes | `attributes` | Object | Additional payment metadata |
| transaction attributes | `attributes` | Object | Alternative description |
| state history | `state_history` | Array | Array of state transition events |
| transaction history | `state_history` | Array | Alternative description |
| route steps | `route_steps` | Array | Array of routing steps |
| routing path | `route_steps` | Array | Alternative description |
| processing duration | Calculated: `last_state_changed_at - created_at` | Number | Time from creation to last state change (milliseconds) |
| processing time | Calculated: `last_state_changed_at - created_at` | Number | Alternative description |
| time to process | Calculated: `last_state_changed_at - created_at` | Number | Alternative description |

### Messages Collection (`messages`)

| Natural Language Description | Actual Field Path | Data Type | Notes |
|------------------------------|------------------|-----------|-------|
| message batch identifier | `external_ref` | String | External reference for the message batch |
| batch reference | `external_ref` | String | Alternative description |
| message ID | `_id` | ObjectId | Primary key |
| batch ID | `_id` | ObjectId | Alternative description |
| source system | `source_system` | String | System that sent the message |
| origin system | `source_system` | String | Alternative description |
| message status | `current_state` | String | Current state: RECEIVED, VALIDATED, SETTLED, etc. |
| batch status | `current_state` | String | Alternative description |
| total payment count | `totals.count` | Number | Number of payments in the batch |
| number of transactions | `totals.count` | Number | Alternative description |
| received timestamp | `received_at` | Date | When message was received |
| message received date | `received_at` | Date | Alternative description |
| last state change | `last_state_changed_at` | Date | When status last changed |
| message attributes | `attributes` | Object | Additional message metadata |
| batch attributes | `attributes` | Object | Alternative description |
| payment IDs list | `payment_ids` | Array | Array of payment ObjectIds in this batch |

### Parties Collection (`parties`)

| Natural Language Description | Actual Field Path | Data Type | Notes |
|------------------------------|------------------|-----------|-------|
| party name | `display_name` | String | Display name of the party |
| entity name | `display_name` | String | Alternative description |
| organization name | `display_name` | String | Alternative description |
| party type | `party_type` | String | DEBTOR, CREDITOR, INTERMEDIARY, BOTH |
| entity type | `party_type` | String | Alternative description |
| party ID | `_id` | ObjectId | Primary key |
| entity ID | `_id` | ObjectId | Alternative description |
| contact email | `email` | String | Email address |
| email address | `email` | String | Alternative description |
| phone number | `phone` | String | Phone number |
| contact phone | `phone` | String | Alternative description |
| associated institution | `institution_id` | ObjectId | Reference to institutions collection |
| bank ID | `institution_id` | ObjectId | Alternative description (requires $lookup) |
| financial institution ID | `institution_id` | ObjectId | Alternative description (requires $lookup) |
| identifiers | `identifiers` | Array | Array of identifier objects (IBAN, account numbers, etc.) |
| account identifiers | `identifiers` | Array | Alternative description |

### Institutions Collection (`institutions`)

| Natural Language Description | Actual Field Path | Data Type | Notes |
|------------------------------|------------------|-----------|-------|
| bank name | `legal_name` | String | Legal name of the institution |
| financial institution name | `legal_name` | String | Alternative description |
| institution name | `legal_name` | String | Alternative description |
| bank code | `bic` | String | Bank Identifier Code |
| BIC code | `bic` | String | Alternative description |
| SWIFT code | `bic` | String | Alternative description |
| legal entity identifier | `lei` | String | Legal Entity Identifier |
| LEI code | `lei` | String | Alternative description |
| country code | `country_code` | String | ISO country code |
| institution country | `country_code` | String | Alternative description |
| bank country | `country_code` | String | Alternative description |

---

## Complex Field Mappings (Requiring Joins or Lookups)

### PostgreSQL - Via JOINs

| Natural Language Description | Access Method | Notes |
|-------------------------------|---------------|-------|
| sender bank name | `p.display_name` from `parties p JOIN payments pay ON pay.debtor_id = p.id` | Requires join to parties table |
| receiver bank name | `p.display_name` from `parties p JOIN payments pay ON pay.creditor_id = p.id` | Requires join to parties table |
| sender institution BIC | `i.bic` from `institutions i JOIN parties p ON p.institution_id = i.id JOIN payments pay ON pay.debtor_id = p.id` | Requires multi-table join |
| receiver institution BIC | `i.bic` from `institutions i JOIN parties p ON p.institution_id = i.id JOIN payments pay ON pay.creditor_id = p.id` | Requires multi-table join |
| message source system | `m.source_system` from `messages m JOIN payments p ON p.message_id = m.id` | Requires join to messages table |
| payment count in batch | `m.total_payments` from `messages m JOIN payments p ON p.message_id = m.id` | Requires join to messages table |

### MongoDB - Via $lookup

| Natural Language Description | Access Method | Notes |
|-------------------------------|---------------|-------|
| sender bank name | `$lookup` from `parties` collection using `debtor_id` | Requires aggregation with $lookup |
| receiver bank name | `$lookup` from `parties` collection using `creditor_id` | Requires aggregation with $lookup |
| sender institution BIC | `$lookup` from `parties` then `$lookup` from `institutions` | Requires nested $lookup |
| receiver institution BIC | `$lookup` from `parties` then `$lookup` from `institutions` | Requires nested $lookup |
| message source system | `$lookup` from `messages` collection using `message_id` | Requires aggregation with $lookup |
| payment count in batch | `$lookup` from `messages, then access `totals.count` | Requires aggregation with $lookup |

---

## Calculated Fields

### PostgreSQL

| Natural Language Description | Calculation | Notes |
|-------------------------------|-------------|-------|
| processing duration | `last_state_changed_at - created_at` | Returns INTERVAL |
| processing duration in seconds | `EXTRACT(EPOCH FROM (last_state_changed_at - created_at))` | Returns numeric seconds |
| processing duration in minutes | `EXTRACT(EPOCH FROM (last_state_changed_at - created_at)) / 60` | Returns numeric minutes |
| days since creation | `CURRENT_DATE - DATE(created_at)` | Returns integer days |
| hours since last update | `EXTRACT(EPOCH FROM (now() - updated_at)) / 3600` | Returns numeric hours |

### MongoDB

| Natural Language Description | Calculation | Notes |
|-------------------------------|-------------|-------|
| processing duration | `$subtract: ["$last_state_changed_at", "$created_at"]` | Returns milliseconds |
| processing duration in seconds | `$divide: [{$subtract: ["$last_state_changed_at", "$created_at"]}, 1000]` | Returns numeric seconds |
| processing duration in minutes | `$divide: [{$subtract: ["$last_state_changed_at", "$created_at"]}, 60000]` | Returns numeric minutes |
| days since creation | `$divide: [{$subtract: [new Date(), "$created_at"]}, 86400000]` | Returns numeric days |

---

## Usage Examples

### Example 1: Simple Field Access

**Natural Language:** "Get the payment amount for all transactions"

**PostgreSQL:**
```sql
SELECT amount FROM payments;
-- amount maps to: payment amount, transaction amount, payment value
```

**MongoDB:**
```javascript
db.payments.find({}, { amount: 1 });
// amount maps to: payment amount, transaction amount, payment value
```

### Example 2: Nested Field Access

**Natural Language:** "Get the sender name for all payments"

**PostgreSQL:**
```sql
SELECT debtor_snapshot->>'display_name' AS sender_name FROM payments;
-- debtor_snapshot->>'display_name' maps to: sender name, payer name
```

**MongoDB:**
```javascript
db.payments.find({}, { "debtor_snapshot.display_name": 1 });
// debtor_snapshot.display_name maps to: sender name, payer name
```

### Example 3: Join Required

**Natural Language:** "Get the sender bank name for all payments"

**PostgreSQL:**
```sql
SELECT p.display_name AS sender_bank_name
FROM payments pay
JOIN parties p ON pay.debtor_id = p.id;
-- Requires join: sender bank name → parties.display_name via debtor_id
```

**MongoDB:**
```javascript
db.payments.aggregate([
  { $lookup: {
      from: "parties",
      localField: "debtor_id",
      foreignField: "_id",
      as: "debtor_party"
    }
  },
  { $project: { sender_bank_name: { $arrayElemAt: ["$debtor_party.display_name", 0] } } }
]);
// Requires $lookup: sender bank name → parties.display_name via debtor_id
```

---

## Notes for SLM Training

1. **Multiple Descriptions**: Many fields have multiple natural language descriptions. The SLM should learn that all variations map to the same column/field.

2. **Context Matters**: Some descriptions are context-dependent:
   - "bank name" could refer to `institutions.legal_name` or `parties.display_name` depending on context
   - "status" could refer to `payment_state` or `message_state` depending on which table is being queried

3. **Calculated Fields**: Some descriptions require calculations, not direct field access.

4. **Join Requirements**: Some descriptions require joining multiple tables or using $lookup in MongoDB.

5. **Nested Structures**: JSONB fields in PostgreSQL and nested objects in MongoDB require special access syntax.

6. **Array Access**: MongoDB arrays and PostgreSQL JSONB arrays require array-specific operations.

