// ============================================================================
// MongoDB Database Initialization Script
// ============================================================================
// This script creates indexes and sample data for the payment processing model
// ============================================================================

// Switch to payment_db
db = db.getSiblingDB('payment_db');

// Create user for payment_db (init scripts run as root before auth)
db.createUser({
  user: 'payment_user',
  pwd: 'payment_pass',
  roles: [
    {
      role: 'readWrite',
      db: 'payment_db'
    }
  ]
});

// ============================================================================
// CREATE INDEXES
// ============================================================================

// payments collection indexes
db.payments.createIndex({ payment_ref: 1 }, { name: "uq_payment_ref", unique: true });
db.payments.createIndex({ message_id: 1 }, { name: "by_message" });
db.payments.createIndex({ scheme: 1, created_at: -1 }, { name: "by_scheme_created" });
db.payments.createIndex({ current_state: 1, last_state_changed_at: -1 }, { name: "state_recent" });
db.payments.createIndex({ "state_history.occurred_at": -1 }, { name: "hist_time" });

// messages collection indexes
db.messages.createIndex({ external_ref: 1 }, { name: "uq_external_ref", unique: true });
db.messages.createIndex({ current_state: 1, last_state_changed_at: -1 }, { name: "state_recent" });

// parties collection indexes
db.parties.createIndex({ display_name: 1 }, { name: "by_name" });
db.parties.createIndex({ "identifiers.value": 1 }, { name: "by_identifier_value" });

// institutions collection indexes
db.institutions.createIndex({ bic: 1 }, { name: "by_bic", unique: true, partialFilterExpression: { bic: { $exists: true } } });
db.institutions.createIndex({ lei: 1 }, { name: "by_lei", unique: true, partialFilterExpression: { lei: { $exists: true } } });

// ============================================================================
// SAMPLE DATA FOR TESTING
// ============================================================================

// Insert sample institutions
db.institutions.insertMany([
  {
    legal_name: "Bank A UK",
    bic: "BKUKGB22XXX",
    lei: "213800D1EI4B9WTWWD28",
    country_code: "GB",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    legal_name: "Bank B UK",
    bic: "BKBKGB2LXXX",
    lei: "5493000KJTIIGC8Y1R13",
    country_code: "GB",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    legal_name: "Correspondent Bank AG",
    bic: "EXCBDEFFXXX",
    lei: "5493001KJTIIGC8Y1R12",
    country_code: "DE",
    created_at: new Date(),
    updated_at: new Date()
  }
]);

// Get institution IDs for parties
var bankAId = db.institutions.findOne({ bic: "BKUKGB22XXX" })._id;
var bankBId = db.institutions.findOne({ bic: "BKBKGB2LXXX" })._id;

// Insert sample parties
db.parties.insertMany([
  {
    party_type: "DEBTOR",
    display_name: "Acme Manufacturing Ltd",
    institution_id: bankAId,
    email: "ap@acme.example",
    phone: "+44-20-1234-5678",
    identifiers: [
      { type: "ACCOUNT_NO", value: "12345678", scheme: "GB-ACCOUNT" },
      { type: "SORT_CODE", value: "12-34-56", scheme: "GB-SORTCODE" }
    ],
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    party_type: "CREDITOR",
    display_name: "Widgets Wholesale PLC",
    institution_id: bankBId,
    email: "info@widgets.example",
    phone: "+44-20-8765-4321",
    identifiers: [
      { type: "ACCOUNT_NO", value: "87654321", scheme: "GB-ACCOUNT" },
      { type: "SORT_CODE", value: "65-43-21", scheme: "GB-SORTCODE" }
    ],
    created_at: new Date(),
    updated_at: new Date()
  }
]);

// Insert sample message
db.messages.insertOne({
  external_ref: "BATCH_TEST_001",
  source_system: "TestSystem",
  current_state: "RECEIVED",
  received_at: new Date(),
  last_state_changed_at: new Date(),
  attributes: {
    format: "ISO20022-pacs.008",
    test: true
  },
  payment_ids: [],
  totals: {
    count: 0,
    by_currency: []
  },
  created_at: new Date(),
  updated_at: new Date()
});

print("MongoDB initialization completed successfully!");
print("Collections created: institutions, parties, messages, payments");
print("Indexes created for all collections");

