// ============================================================================
// MongoDB CRUD Operations for Payment Processing Model
// ============================================================================
// Comprehensive NoSQL examples for training SLM on text-to-NoSQL and SQL↔NoSQL
// ============================================================================

// ============================================================================
// INSTITUTIONS - CREATE Operations
// ============================================================================

// Insert a single institution
db.institutions.insertOne({
  legal_name: "Example Bank Ltd",
  bic: "EXBKGB22XXX",
  lei: "5493001KJTIIGC8Y1R12",
  country_code: "GB",
  created_at: new Date(),
  updated_at: new Date()
});

// Insert institution with only required fields
db.institutions.insertOne({
  legal_name: "Simple Bank Inc",
  created_at: new Date(),
  updated_at: new Date()
});

// Insert multiple institutions (bulk insert)
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

// Insert with explicit _id (if needed)
db.institutions.insertOne({
  _id: ObjectId("6755f0b2c3a9b2f3d4a10001"),
  legal_name: "Custom Bank",
  bic: "CUSTGB22XXX",
  country_code: "GB",
  created_at: new Date(),
  updated_at: new Date()
});

// ============================================================================
// INSTITUTIONS - READ Operations
// ============================================================================

// Get institution by _id
db.institutions.findOne({ _id: ObjectId("6755f0b2c3a9b2f3d4a10001") });

// Get institution by BIC
db.institutions.findOne({ bic: "EXBKGB22XXX" });

// Get institution by LEI
db.institutions.findOne({ lei: "5493001KJTIIGC8Y1R12" });

// Get all institutions
db.institutions.find().sort({ created_at: -1 });

// Get institutions by country
db.institutions.find({ country_code: "GB" }).sort({ legal_name: 1 });

// Get institutions with pagination (limit/skip)
db.institutions.find().sort({ created_at: -1 }).limit(10).skip(0);

// Search institutions by name pattern
db.institutions.find({ legal_name: /Bank/i }).sort({ legal_name: 1 });

// Get institutions created in date range
db.institutions.find({
  created_at: {
    $gte: ISODate("2025-01-01T00:00:00Z"),
    $lt: ISODate("2025-12-31T23:59:59Z")
  }
}).sort({ created_at: -1 });

// Count institutions by country
db.institutions.aggregate([
  { $group: { _id: "$country_code", institution_count: { $sum: 1 } } },
  { $sort: { institution_count: -1 } }
]);

// Get institutions with BIC or LEI (not null)
db.institutions.find({
  $or: [
    { bic: { $exists: true, $ne: null } },
    { lei: { $exists: true, $ne: null } }
  ]
}).sort({ legal_name: 1 });

// Get institutions with multiple conditions
db.institutions.find({
  country_code: "GB",
  $or: [
    { bic: { $exists: true } },
    { lei: { $exists: true } }
  ]
}).sort({ legal_name: 1 });

// ============================================================================
// INSTITUTIONS - UPDATE Operations
// ============================================================================

// Update single field
db.institutions.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a10001") },
  { $set: { legal_name: "Updated Bank Name Ltd" } }
);

// Update multiple fields
db.institutions.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a10001") },
  {
    $set: {
      legal_name: "New Bank Name",
      bic: "NEWBGB22XXX",
      updated_at: new Date()
    }
  }
);

// Update with conditional logic
db.institutions.updateMany(
  {
    country_code: { $exists: false },
    legal_name: /Bank/
  },
  {
    $set: {
      country_code: "US",
      updated_at: new Date()
    }
  }
);

// Update all institutions' updated_at timestamp
db.institutions.updateMany(
  { updated_at: { $lt: new Date(Date.now() - 24 * 60 * 60 * 1000) } },
  { $set: { updated_at: new Date() } }
);

// Update with increment (if needed)
db.institutions.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a10001") },
  { $set: { updated_at: new Date() } }
);

// Replace entire document
db.institutions.replaceOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a10001") },
  {
    legal_name: "Replaced Bank Name",
    bic: "REPLGB22XXX",
    country_code: "GB",
    created_at: new Date(),
    updated_at: new Date()
  }
);

// ============================================================================
// INSTITUTIONS - DELETE Operations
// ============================================================================

// Delete institution by _id
db.institutions.deleteOne({ _id: ObjectId("6755f0b2c3a9b2f3d4a10001") });

// Delete institutions by country
db.institutions.deleteMany({ country_code: "XX" });

// Delete institutions with no BIC or LEI
db.institutions.deleteMany({
  bic: { $exists: false },
  lei: { $exists: false }
});

// Delete institutions matching condition
db.institutions.deleteMany({
  country_code: null,
  legal_name: /Test/
});

// ============================================================================
// PARTIES - CREATE Operations
// ============================================================================

// Insert a single party
db.parties.insertOne({
  party_type: "DEBTOR",
  display_name: "Acme Manufacturing Ltd",
  institution_id: ObjectId("6755f0b2c3a9b2f3d4a10001"),
  email: "ap@acme.example",
  phone: "+44-20-1234-5678",
  identifiers: [
    { type: "ACCOUNT_NO", value: "12345678", scheme: "GB-ACCOUNT" },
    { type: "SORT_CODE", value: "12-34-56", scheme: "GB-SORTCODE" },
    { type: "LEI", value: "5493001KJTIIGC8Y1R12" }
  ],
  created_at: new Date(),
  updated_at: new Date()
});

// Insert party without institution (standalone)
db.parties.insertOne({
  party_type: "CREDITOR",
  display_name: "Widgets Wholesale PLC",
  email: "info@widgets.example",
  identifiers: [],
  created_at: new Date(),
  updated_at: new Date()
});

// Insert party with all fields
db.parties.insertOne({
  party_type: "BOTH",
  display_name: "Universal Trading Co",
  institution_id: ObjectId("6755f0b2c3a9b2f3d4a10001"),
  email: "contact@universal.example",
  phone: "+1-555-123-4567",
  identifiers: [
    { type: "IBAN", value: "GB82WEST12345698765432", scheme: "ISO13616" }
  ],
  created_at: new Date(),
  updated_at: new Date()
});

// Bulk insert parties
db.parties.insertMany([
  {
    party_type: "DEBTOR",
    display_name: "Company A",
    institution_id: ObjectId("6755f0b2c3a9b2f3d4a10001"),
    email: "a@company.example",
    identifiers: [],
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    party_type: "CREDITOR",
    display_name: "Company B",
    institution_id: ObjectId("6755f0b2c3a9b2f3d4a10002"),
    email: "b@company.example",
    identifiers: [],
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    party_type: "INTERMEDIARY",
    display_name: "Company C",
    email: "c@company.example",
    identifiers: [],
    created_at: new Date(),
    updated_at: new Date()
  }
]);

// ============================================================================
// PARTIES - READ Operations
// ============================================================================

// Get party by _id
db.parties.findOne({ _id: ObjectId("6755f0b2c3a9b2f3d4a20001") });

// Get parties by type
db.parties.find({ party_type: "DEBTOR" }).sort({ display_name: 1 });

// Get parties with institution (using lookup/aggregation)
db.parties.aggregate([
  { $match: { party_type: "DEBTOR" } },
  {
    $lookup: {
      from: "institutions",
      localField: "institution_id",
      foreignField: "_id",
      as: "institution"
    }
  },
  { $unwind: { path: "$institution", preserveNullAndEmptyArrays: true } },
  { $sort: { display_name: 1 } }
]);

// Get parties by institution
db.parties.find({
  institution_id: ObjectId("6755f0b2c3a9b2f3d4a10001")
}).sort({ display_name: 1 });

// Search parties by name
db.parties.find({
  display_name: /Manufacturing/i
}).sort({ display_name: 1 });

// Get parties with pagination
db.parties.find().sort({ created_at: -1 }).limit(20).skip(0);

// Get parties created in date range
db.parties.find({
  created_at: {
    $gte: ISODate("2025-01-01T00:00:00Z"),
    $lt: ISODate("2025-12-31T23:59:59Z")
  }
}).sort({ created_at: -1 });

// Count parties by type
db.parties.aggregate([
  { $group: { _id: "$party_type", count: { $sum: 1 } } },
  { $sort: { count: -1 } }
]);

// Get parties with email domain
db.parties.find({
  email: /@example\.com$/
}).sort({ display_name: 1 });

// Get parties with specific identifier
db.parties.find({
  "identifiers.value": "12345678"
});

// Get parties with identifier type
db.parties.find({
  "identifiers.type": "IBAN"
});

// ============================================================================
// PARTIES - UPDATE Operations
// ============================================================================

// Update single field
db.parties.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a20001") },
  { $set: { display_name: "Updated Company Name" } }
);

// Update multiple fields
db.parties.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a20001") },
  {
    $set: {
      display_name: "New Company Name",
      email: "newemail@example.com",
      phone: "+44-20-9999-9999",
      updated_at: new Date()
    }
  }
);

// Update party type
db.parties.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a20001") },
  {
    $set: {
      party_type: "BOTH",
      updated_at: new Date()
    }
  }
);

// Update institution association
db.parties.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a20001") },
  {
    $set: {
      institution_id: ObjectId("6755f0b2c3a9b2f3d4a10002"),
      updated_at: new Date()
    }
  }
);

// Add identifier to array
db.parties.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a20001") },
  {
    $push: {
      identifiers: {
        type: "IBAN",
        value: "GB82WEST12345698765432",
        scheme: "ISO13616"
      }
    },
    $set: { updated_at: new Date() }
  }
);

// Remove identifier from array
db.parties.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a20001") },
  {
    $pull: {
      identifiers: { type: "SORT_CODE" }
    },
    $set: { updated_at: new Date() }
  }
);

// Update specific identifier in array
db.parties.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a20001"), "identifiers.type": "ACCOUNT_NO" },
  {
    $set: {
      "identifiers.$.value": "99999999",
      "identifiers.$.scheme": "UPDATED-SCHEME",
      updated_at: new Date()
    }
  }
);

// Replace entire identifiers array
db.parties.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a20001") },
  {
    $set: {
      identifiers: [
        { type: "IBAN", value: "GB82WEST12345698765432", scheme: "ISO13616" }
      ],
      updated_at: new Date()
    }
  }
);

// ============================================================================
// PARTIES - DELETE Operations
// ============================================================================

// Delete party by _id
db.parties.deleteOne({ _id: ObjectId("6755f0b2c3a9b2f3d4a20001") });

// Delete parties by type
db.parties.deleteMany({ party_type: "INTERMEDIARY" });

// Delete parties matching condition
db.parties.deleteMany({
  email: /@test\./
});

// ============================================================================
// MESSAGES - CREATE Operations
// ============================================================================

// Insert a single message
db.messages.insertOne({
  external_ref: "BATCH_2025-11-08_001",
  source_system: "UpstreamGateway-A",
  current_state: "RECEIVED",
  received_at: new Date(),
  last_state_changed_at: new Date(),
  attributes: {
    format: "ISO20022-pacs.008",
    file_hash: "sha256:abcd1234"
  },
  payment_ids: [],
  totals: {
    count: 0,
    by_currency: []
  },
  created_at: new Date(),
  updated_at: new Date()
});

// Insert message with all fields
db.messages.insertOne({
  external_ref: "BATCH_2025-11-08_002",
  source_system: "UpstreamGateway-B",
  current_state: "VALIDATED",
  received_at: ISODate("2025-11-08T10:00:00Z"),
  last_state_changed_at: ISODate("2025-11-08T10:00:00Z"),
  attributes: {
    format: "ISO20022-pacs.008",
    file_hash: "sha256:abcd1234"
  },
  payment_ids: [
    ObjectId("6755f0b2c3a9b2f3d4a40001"),
    ObjectId("6755f0b2c3a9b2f3d4a40002")
  ],
  totals: {
    count: 2,
    by_currency: [
      { currency: "GBP", count: 2, sum: NumberDecimal("2050.00") }
    ]
  },
  created_at: new Date(),
  updated_at: new Date()
});

// Insert message with default state
db.messages.insertOne({
  external_ref: "BATCH_2025-11-08_003",
  source_system: "UpstreamGateway-C",
  current_state: "RECEIVED",
  received_at: new Date(),
  last_state_changed_at: new Date(),
  attributes: {},
  payment_ids: [],
  totals: { count: 0, by_currency: [] },
  created_at: new Date(),
  updated_at: new Date()
});

// Bulk insert messages
db.messages.insertMany([
  {
    external_ref: "BATCH_001",
    source_system: "System-A",
    current_state: "RECEIVED",
    received_at: new Date(),
    last_state_changed_at: new Date(),
    attributes: {},
    payment_ids: [],
    totals: { count: 0, by_currency: [] },
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    external_ref: "BATCH_002",
    source_system: "System-B",
    current_state: "RECEIVED",
    received_at: new Date(),
    last_state_changed_at: new Date(),
    attributes: {},
    payment_ids: [],
    totals: { count: 0, by_currency: [] },
    created_at: new Date(),
    updated_at: new Date()
  }
]);

// ============================================================================
// MESSAGES - READ Operations
// ============================================================================

// Get message by _id
db.messages.findOne({ _id: ObjectId("6755f0b2c3a9b2f3d4a30001") });

// Get message by external_ref
db.messages.findOne({ external_ref: "BATCH_2025-11-08_001" });

// Get messages by state
db.messages.find({ current_state: "RECEIVED" }).sort({ received_at: -1 });

// Get messages by source system
db.messages.find({ source_system: "UpstreamGateway-A" }).sort({ received_at: -1 });

// Get messages with pagination
db.messages.find().sort({ received_at: -1 }).limit(50).skip(0);

// Get messages in date range
db.messages.find({
  received_at: {
    $gte: ISODate("2025-11-08T00:00:00Z"),
    $lt: ISODate("2025-11-09T00:00:00Z")
  }
}).sort({ received_at: -1 });

// Get messages by state and time range
db.messages.find({
  current_state: "SETTLED",
  last_state_changed_at: {
    $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
  }
}).sort({ last_state_changed_at: -1 });

// Query nested attributes
db.messages.find({
  "attributes.format": "ISO20022-pacs.008"
});

// Query with attribute key exists
db.messages.find({
  "attributes.file_hash": { $exists: true }
});

// Query with attribute contains (using $elemMatch for arrays if needed)
db.messages.find({
  "attributes.format": { $exists: true }
});

// Count messages by state
db.messages.aggregate([
  { $group: { _id: "$current_state", count: { $sum: 1 } } },
  { $sort: { count: -1 } }
]);

// Count messages by source system
db.messages.aggregate([
  {
    $group: {
      _id: "$source_system",
      count: { $sum: 1 },
      total_payment_count: { $sum: "$totals.count" }
    }
  },
  { $sort: { count: -1 } }
]);

// Get messages with payment count filter
db.messages.find({
  "totals.count": { $gt: 10 }
}).sort({ "totals.count": -1 });

// Get messages with payments (using lookup)
db.messages.aggregate([
  { $match: { _id: ObjectId("6755f0b2c3a9b2f3d4a30001") } },
  {
    $lookup: {
      from: "payments",
      localField: "_id",
      foreignField: "message_id",
      as: "payments"
    }
  }
]);

// ============================================================================
// MESSAGES - UPDATE Operations
// ============================================================================

// Update message state
db.messages.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a30001") },
  {
    $set: {
      current_state: "VALIDATED",
      last_state_changed_at: new Date(),
      updated_at: new Date()
    }
  }
);

// Update multiple fields
db.messages.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a30001") },
  {
    $set: {
      current_state: "ENRICHED",
      "totals.count": 5,
      last_state_changed_at: new Date(),
      updated_at: new Date()
    }
  }
);

// Update nested attributes
db.messages.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a30001") },
  {
    $set: {
      "attributes.new_key": "new_value",
      updated_at: new Date()
    }
  }
);

// Update specific nested key
db.messages.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a30001") },
  {
    $set: {
      "attributes.priority": "HIGH",
      updated_at: new Date()
    }
  }
);

// Add payment_id to array
db.messages.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a30001") },
  {
    $push: {
      payment_ids: ObjectId("6755f0b2c3a9b2f3d4a40001")
    },
    $inc: { "totals.count": 1 },
    $set: { updated_at: new Date() }
  }
);

// Remove payment_id from array
db.messages.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a30001") },
  {
    $pull: {
      payment_ids: ObjectId("6755f0b2c3a9b2f3d4a40001")
    },
    $inc: { "totals.count": -1 },
    $set: { updated_at: new Date() }
  }
);

// Update totals.by_currency array
db.messages.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a30001") },
  {
    $set: {
      "totals.by_currency": [
        { currency: "GBP", count: 2, sum: NumberDecimal("2050.00") },
        { currency: "EUR", count: 1, sum: NumberDecimal("500.00") }
      ],
      updated_at: new Date()
    }
  }
);

// ============================================================================
// MESSAGES - DELETE Operations
// ============================================================================

// Delete message by _id
db.messages.deleteOne({ _id: ObjectId("6755f0b2c3a9b2f3d4a30001") });

// Delete messages by external_ref
db.messages.deleteOne({ external_ref: "BATCH_2025-11-08_001" });

// Delete messages by state
db.messages.deleteMany({ current_state: "FAILED" });

// ============================================================================
// PAYMENTS - CREATE Operations
// ============================================================================

// Insert single payment
db.payments.insertOne({
  message_id: ObjectId("6755f0b2c3a9b2f3d4a30001"),
  payment_ref: "PMT-2025-11-08-0001",
  scheme: "FPS",
  amount: NumberDecimal("2000.00"),
  currency: "GBP",
  current_state: "RECEIVED",
  last_state_changed_at: new Date(),
  instructed_on: new Date(),
  debtor_snapshot: {
    display_name: "Acme Manufacturing Ltd",
    identifiers: [
      { type: "ACCOUNT_NO", value: "12345678", scheme: "GB-ACCOUNT" },
      { type: "SORT_CODE", value: "12-34-56", scheme: "GB-SORTCODE" }
    ],
    address: {
      line1: "1 King St",
      city: "London",
      country: "GB"
    }
  },
  creditor_snapshot: {
    display_name: "Widgets Wholesale PLC",
    identifiers: [
      { type: "ACCOUNT_NO", value: "87654321", scheme: "GB-ACCOUNT" },
      { type: "SORT_CODE", value: "65-43-21", scheme: "GB-SORTCODE" }
    ],
    address: {
      line1: "55 Queen Rd",
      city: "Manchester",
      country: "GB"
    }
  },
  debtor_id: ObjectId("6755f0b2c3a9b2f3d4a20001"),
  creditor_id: ObjectId("6755f0b2c3a9b2f3d4a20002"),
  route_steps: [
    {
      step_no: 1,
      role: "SENDER_BANK",
      institution_snapshot: {
        legal_name: "Bank A UK",
        bic: "BKUKGB22XXX",
        lei: "213800D1EI4B9WTWWD28",
        country_code: "GB"
      },
      metadata: { channel: "API" }
    },
    {
      step_no: 2,
      role: "INTERMEDIARY",
      institution_snapshot: {
        legal_name: "Example Correspondent Bank AG",
        bic: "EXCBDEFFXXX",
        lei: "5493001KJTIIGC8Y1R12",
        country_code: "DE"
      },
      metadata: { corridor: "GB-DE-GB" }
    },
    {
      step_no: 3,
      role: "RECEIVER_BANK",
      institution_snapshot: {
        legal_name: "Bank B UK",
        bic: "BKBKGB2LXXX",
        country_code: "GB"
      }
    }
  ],
  state_history: [
    {
      seq_no: 1,
      from_state: null,
      to_state: "RECEIVED",
      actor: { type: "SYSTEM", id: "ingestion-svc" },
      occurred_at: new Date(),
      metadata: { source: "UpstreamGateway-A" }
    }
  ],
  route_summary: {
    method: "DIRECT",
    estimated_settlement: new Date(Date.now() + 2 * 60 * 1000)
  },
  attributes: {
    priority: "HIGH",
    fee_model: "OUR"
  },
  created_at: new Date(),
  updated_at: new Date()
});

// Insert payment with minimal fields
db.payments.insertOne({
  message_id: ObjectId("6755f0b2c3a9b2f3d4a30001"),
  payment_ref: "PMT-2025-11-08-0002",
  scheme: "FPS",
  amount: NumberDecimal("50.00"),
  currency: "GBP",
  current_state: "RECEIVED",
  last_state_changed_at: new Date(),
  instructed_on: new Date(),
  debtor_snapshot: {
    display_name: "Debtor Co",
    identifiers: []
  },
  creditor_snapshot: {
    display_name: "Creditor Co",
    identifiers: []
  },
  state_history: [
    {
      seq_no: 1,
      from_state: null,
      to_state: "RECEIVED",
      actor: { type: "SYSTEM" },
      occurred_at: new Date(),
      metadata: {}
    }
  ],
  route_steps: [],
  route_summary: {},
  attributes: {},
  created_at: new Date(),
  updated_at: new Date()
});

// Bulk insert payments
db.payments.insertMany([
  {
    message_id: ObjectId("6755f0b2c3a9b2f3d4a30001"),
    payment_ref: "PMT-001",
    scheme: "FPS",
    amount: NumberDecimal("100.00"),
    currency: "GBP",
    current_state: "RECEIVED",
    last_state_changed_at: new Date(),
    instructed_on: new Date(),
    debtor_snapshot: { display_name: "Debtor 1", identifiers: [] },
    creditor_snapshot: { display_name: "Creditor 1", identifiers: [] },
    state_history: [{
      seq_no: 1,
      from_state: null,
      to_state: "RECEIVED",
      actor: { type: "SYSTEM" },
      occurred_at: new Date(),
      metadata: {}
    }],
    route_steps: [],
    route_summary: {},
    attributes: {},
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    message_id: ObjectId("6755f0b2c3a9b2f3d4a30001"),
    payment_ref: "PMT-002",
    scheme: "FPS",
    amount: NumberDecimal("200.00"),
    currency: "GBP",
    current_state: "RECEIVED",
    last_state_changed_at: new Date(),
    instructed_on: new Date(),
    debtor_snapshot: { display_name: "Debtor 2", identifiers: [] },
    creditor_snapshot: { display_name: "Creditor 2", identifiers: [] },
    state_history: [{
      seq_no: 1,
      from_state: null,
      to_state: "RECEIVED",
      actor: { type: "SYSTEM" },
      occurred_at: new Date(),
      metadata: {}
    }],
    route_steps: [],
    route_summary: {},
    attributes: {},
    created_at: new Date(),
    updated_at: new Date()
  }
]);

// ============================================================================
// PAYMENTS - READ Operations
// ============================================================================

// Get payment by _id
db.payments.findOne({ _id: ObjectId("6755f0b2c3a9b2f3d4a40001") });

// Get payment by payment_ref
db.payments.findOne({ payment_ref: "PMT-2025-11-08-0001" });

// Get payments by message
db.payments.find({
  message_id: ObjectId("6755f0b2c3a9b2f3d4a30001")
}).sort({ created_at: 1 });

// Get payments by state
db.payments.find({ current_state: "SETTLED" }).sort({ last_state_changed_at: -1 });

// Get payments by scheme
db.payments.find({ scheme: "FPS" }).sort({ created_at: -1 });

// Get payments by currency
db.payments.find({ currency: "GBP" }).sort({ amount: -1 });

// Get payments with amount filter
db.payments.find({
  amount: { $gt: NumberDecimal("1000.00") }
}).sort({ amount: -1 });

// Get payments in amount range
db.payments.find({
  amount: {
    $gte: NumberDecimal("100.00"),
    $lte: NumberDecimal("5000.00")
  }
}).sort({ amount: 1 });

// Get payments with pagination
db.payments.find().sort({ created_at: -1 }).limit(100).skip(0);

// Get payments in date range
db.payments.find({
  created_at: {
    $gte: ISODate("2025-11-08T00:00:00Z"),
    $lt: ISODate("2025-11-09T00:00:00Z")
  }
}).sort({ created_at: -1 });

// Get payments by state and time range
db.payments.find({
  current_state: "PENDING_FUNDS",
  last_state_changed_at: {
    $gte: new Date(Date.now() - 60 * 60 * 1000)
  }
}).sort({ last_state_changed_at: -1 });

// Query nested debtor_snapshot
db.payments.find({
  "debtor_snapshot.display_name": "Acme Manufacturing Ltd"
});

// Query nested with contains
db.payments.find({
  "debtor_snapshot.display_name": /Acme/
});

// Query nested identifiers array
db.payments.find({
  "debtor_snapshot.identifiers.type": "ACCOUNT_NO"
});

// Query nested identifiers with $elemMatch
db.payments.find({
  "debtor_snapshot.identifiers": {
    $elemMatch: {
      type: "ACCOUNT_NO",
      value: "12345678"
    }
  }
});

// Get payments with route_summary query
db.payments.find({
  "route_summary.method": "DIRECT"
});

// Get payments with attributes query
db.payments.find({
  "attributes.priority": "HIGH"
});

// Get payments with message details (using lookup)
db.payments.aggregate([
  { $match: { current_state: "REJECTED" } },
  {
    $lookup: {
      from: "messages",
      localField: "message_id",
      foreignField: "_id",
      as: "message"
    }
  },
  { $unwind: { path: "$message", preserveNullAndEmptyArrays: true } },
  { $sort: { last_state_changed_at: -1 } }
]);

// Get payments with party details (using lookup)
db.payments.aggregate([
  { $match: { amount: { $gt: NumberDecimal("1000.00") } } },
  {
    $lookup: {
      from: "parties",
      localField: "debtor_id",
      foreignField: "_id",
      as: "debtor"
    }
  },
  {
    $lookup: {
      from: "parties",
      localField: "creditor_id",
      foreignField: "_id",
      as: "creditor"
    }
  },
  { $unwind: { path: "$debtor", preserveNullAndEmptyArrays: true } },
  { $unwind: { path: "$creditor", preserveNullAndEmptyArrays: true } }
]);

// Count payments by state
db.payments.aggregate([
  {
    $group: {
      _id: "$current_state",
      count: { $sum: 1 },
      total_amount: { $sum: "$amount" }
    }
  },
  { $sort: { count: -1 } }
]);

// Count payments by scheme
db.payments.aggregate([
  {
    $group: {
      _id: "$scheme",
      count: { $sum: 1 },
      total_amount: { $sum: "$amount" }
    }
  },
  { $sort: { count: -1 } }
]);

// Count payments by currency
db.payments.aggregate([
  {
    $group: {
      _id: "$currency",
      count: { $sum: 1 },
      total_amount: { $sum: "$amount" }
    }
  },
  { $sort: { total_amount: -1 } }
]);

// Get payment statistics
db.payments.aggregate([
  {
    $group: {
      _id: null,
      total_payments: { $sum: 1 },
      total_amount: { $sum: "$amount" },
      avg_amount: { $avg: "$amount" },
      min_amount: { $min: "$amount" },
      max_amount: { $max: "$amount" },
      currency_count: { $addToSet: "$currency" }
    }
  },
  {
    $project: {
      _id: 0,
      total_payments: 1,
      total_amount: 1,
      avg_amount: 1,
      min_amount: 1,
      max_amount: 1,
      currency_count: { $size: "$currency_count" }
    }
  }
]);

// Get payments with state history query
db.payments.find({
  "state_history.to_state": "REJECTED"
});

// Get payments with specific state transition
db.payments.find({
  "state_history": {
    $elemMatch: {
      from_state: "VALIDATED",
      to_state: "REJECTED"
    }
  }
});

// Get payments with route step query
db.payments.find({
  "route_steps.role": "INTERMEDIARY"
});

// Get payments with route step by BIC
db.payments.find({
  "route_steps.institution_snapshot.bic": "EXCBDEFFXXX"
});

// ============================================================================
// PAYMENTS - UPDATE Operations
// ============================================================================

// Update payment state
db.payments.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a40001") },
  {
    $set: {
      current_state: "VALIDATED",
      last_state_changed_at: new Date(),
      updated_at: new Date()
    }
  }
);

// Update multiple fields
db.payments.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a40001") },
  {
    $set: {
      current_state: "ROUTED",
      last_state_changed_at: new Date(),
      "route_summary.method": "DIRECT",
      "route_summary.estimated_settlement": new Date(Date.now() + 2 * 60 * 1000),
      updated_at: new Date()
    }
  }
);

// Update JSONB attributes
db.payments.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a40001") },
  {
    $set: {
      "attributes.new_key": "new_value",
      updated_at: new Date()
    }
  }
);

// Update specific JSONB key
db.payments.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a40001") },
  {
    $set: {
      "route_summary.method": "INDIRECT",
      updated_at: new Date()
    }
  }
);

// Update amount
db.payments.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a40001") },
  {
    $set: {
      amount: NumberDecimal("2500.00"),
      updated_at: new Date()
    }
  }
);

// Add route step to array
db.payments.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a40001") },
  {
    $push: {
      route_steps: {
        step_no: 4,
        role: "RECEIVER_BANK",
        institution_snapshot: {
          legal_name: "Final Bank",
          bic: "FINALGB22XXX",
          country_code: "GB"
        }
      }
    },
    $set: { updated_at: new Date() }
  }
);

// Remove route step from array
db.payments.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a40001") },
  {
    $pull: {
      route_steps: { step_no: 3 }
    },
    $set: { updated_at: new Date() }
  }
);

// Update specific route step in array
db.payments.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a40001"), "route_steps.step_no": 2 },
  {
    $set: {
      "route_steps.$.institution_snapshot.legal_name": "Updated Bank Name",
      "route_steps.$.metadata.updated": true,
      updated_at: new Date()
    }
  }
);

// Append to state_history (atomic update)
db.payments.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a40001") },
  {
    $push: {
      state_history: {
        seq_no: 2,
        from_state: "RECEIVED",
        to_state: "VALIDATED",
        actor: { type: "SYSTEM", id: "validation-svc" },
        occurred_at: new Date(),
        metadata: { aml: "PASS" }
      }
    },
    $set: {
      current_state: "VALIDATED",
      last_state_changed_at: new Date(),
      updated_at: new Date()
    }
  }
);

// Update state_history with incrementing seq_no
db.payments.updateOne(
  { _id: ObjectId("6755f0b2c3a9b2f3d4a40001") },
  [
    {
      $set: {
        new_seq_no: {
          $ifNull: [
            { $add: [{ $max: "$state_history.seq_no" }, 1] },
            1
          ]
        }
      }
    },
    {
      $set: {
        state_history: {
          $concatArrays: [
            "$state_history",
            [
              {
                seq_no: "$new_seq_no",
                from_state: "$current_state",
                to_state: "ROUTED",
                actor: { type: "SYSTEM", id: "routing-svc" },
                occurred_at: new Date(),
                metadata: { corridor: "FPS:Direct" }
              }
            ]
          ]
        },
        current_state: "ROUTED",
        last_state_changed_at: new Date(),
        updated_at: new Date()
      }
    },
    {
      $unset: "new_seq_no"
    }
  ]
);

// ============================================================================
// PAYMENTS - DELETE Operations
// ============================================================================

// Delete payment by _id
db.payments.deleteOne({ _id: ObjectId("6755f0b2c3a9b2f3d4a40001") });

// Delete payments by payment_ref
db.payments.deleteOne({ payment_ref: "PMT-2025-11-08-0001" });

// Delete payments by state
db.payments.deleteMany({ current_state: "FAILED" });

// ============================================================================
// COMPLEX QUERIES - Aggregation Pipelines
// ============================================================================

// Get payment with full details (message, parties, route steps, events)
db.payments.aggregate([
  { $match: { _id: ObjectId("6755f0b2c3a9b2f3d4a40001") } },
  {
    $lookup: {
      from: "messages",
      localField: "message_id",
      foreignField: "_id",
      as: "message"
    }
  },
  {
    $lookup: {
      from: "parties",
      localField: "debtor_id",
      foreignField: "_id",
      as: "debtor"
    }
  },
  {
    $lookup: {
      from: "parties",
      localField: "creditor_id",
      foreignField: "_id",
      as: "creditor"
    }
  },
  {
    $project: {
      _id: 1,
      payment_ref: 1,
      scheme: 1,
      amount: 1,
      currency: 1,
      current_state: 1,
      message_ref: { $arrayElemAt: ["$message.external_ref", 0] },
      source_system: { $arrayElemAt: ["$message.source_system", 0] },
      debtor_name: { $arrayElemAt: ["$debtor.display_name", 0] },
      creditor_name: { $arrayElemAt: ["$creditor.display_name", 0] },
      route_step_count: { $size: { $ifNull: ["$route_steps", []] } },
      event_count: { $size: { $ifNull: ["$state_history", []] } }
    }
  }
]);

// Get message with all payments and their states
db.messages.aggregate([
  { $match: { _id: ObjectId("6755f0b2c3a9b2f3d4a30001") } },
  {
    $lookup: {
      from: "payments",
      localField: "_id",
      foreignField: "message_id",
      as: "payments"
    }
  },
  {
    $project: {
      _id: 1,
      external_ref: 1,
      source_system: 1,
      current_state: 1,
      payment_count: { $size: "$payments" },
      total_amount: { $sum: "$payments.amount" },
      settled_count: {
        $size: {
          $filter: {
            input: "$payments",
            as: "p",
            cond: { $eq: ["$$p.current_state", "SETTLED"] }
          }
        }
      },
      rejected_count: {
        $size: {
          $filter: {
            input: "$payments",
            as: "p",
            cond: { $eq: ["$$p.current_state", "REJECTED"] }
          }
        }
      }
    }
  }
]);

// Get payment state transition timeline
db.payments.aggregate([
  { $match: { _id: ObjectId("6755f0b2c3a9b2f3d4a40001") } },
  { $unwind: "$state_history" },
  { $sort: { "state_history.seq_no": 1 } },
  {
    $project: {
      seq_no: "$state_history.seq_no",
      from_state: "$state_history.from_state",
      to_state: "$state_history.to_state",
      occurred_at: "$state_history.occurred_at",
      actor_type: "$state_history.actor.type",
      actor_id: "$state_history.actor.id",
      reason_code: "$state_history.metadata.reason_code"
    }
  }
]);

// Get payments with route details
db.payments.aggregate([
  { $match: { _id: ObjectId("6755f0b2c3a9b2f3d4a40001") } },
  { $unwind: { path: "$route_steps", preserveNullAndEmptyArrays: true } },
  {
    $project: {
      payment_ref: 1,
      scheme: 1,
      amount: 1,
      currency: 1,
      step_no: "$route_steps.step_no",
      role: "$route_steps.role",
      institution_name: "$route_steps.institution_snapshot.legal_name",
      bic: "$route_steps.institution_snapshot.bic"
    }
  },
  { $sort: { step_no: 1 } }
]);

// Get party with all identifiers
db.parties.aggregate([
  { $match: { _id: ObjectId("6755f0b2c3a9b2f3d4a20001") } },
  {
    $project: {
      _id: 1,
      party_type: 1,
      display_name: 1,
      email: 1,
      phone: 1,
      institution_id: 1,
      identifiers: {
        $map: {
          input: { $ifNull: ["$identifiers", []] },
          as: "id",
          in: {
            id: "$$id._id",
            type: "$$id.type",
            value: "$$id.value",
            scheme: "$$id.scheme"
          }
        }
      },
      created_at: 1,
      updated_at: 1
    }
  }
]);

// ============================================================================
// TRANSACTION Examples (using sessions)
// ============================================================================

// Transaction: Create message with payment and state history
var session = db.getMongo().startSession();
session.startTransaction();

try {
  var messageResult = db.messages.insertOne({
    external_ref: "BATCH_TXN_001",
    source_system: "System-A",
    current_state: "RECEIVED",
    received_at: new Date(),
    last_state_changed_at: new Date(),
    attributes: {},
    payment_ids: [],
    totals: { count: 0, by_currency: [] },
    created_at: new Date(),
    updated_at: new Date()
  }, { session: session });

  var paymentResult = db.payments.insertOne({
    message_id: messageResult.insertedId,
    payment_ref: "PMT-TXN-001",
    scheme: "FPS",
    amount: NumberDecimal("1000.00"),
    currency: "GBP",
    current_state: "RECEIVED",
    last_state_changed_at: new Date(),
    instructed_on: new Date(),
    debtor_snapshot: { display_name: "Debtor", identifiers: [] },
    creditor_snapshot: { display_name: "Creditor", identifiers: [] },
    state_history: [{
      seq_no: 1,
      from_state: null,
      to_state: "RECEIVED",
      actor: { type: "SYSTEM" },
      occurred_at: new Date(),
      metadata: {}
    }],
    route_steps: [],
    route_summary: {},
    attributes: {},
    created_at: new Date(),
    updated_at: new Date()
  }, { session: session });

  db.messages.updateOne(
    { _id: messageResult.insertedId },
    {
      $push: { payment_ids: paymentResult.insertedId },
      $set: { "totals.count": 1, updated_at: new Date() }
    },
    { session: session }
  );

  session.commitTransaction();
} catch (error) {
  session.abortTransaction();
  throw error;
} finally {
  session.endSession();
}

// Transaction: Update payment state with state history logging
var session = db.getMongo().startSession();
session.startTransaction();

try {
  var payment = db.payments.findOne(
    { _id: ObjectId("6755f0b2c3a9b2f3d4a40001") },
    { session: session }
  );

  var nextSeqNo = payment.state_history.length > 0
    ? Math.max(...payment.state_history.map(h => h.seq_no)) + 1
    : 1;

  db.payments.updateOne(
    { _id: ObjectId("6755f0b2c3a9b2f3d4a40001") },
    {
      $push: {
        state_history: {
          seq_no: nextSeqNo,
          from_state: payment.current_state,
          to_state: "VALIDATED",
          actor: { type: "SYSTEM", id: "validation-svc" },
          occurred_at: new Date(),
          metadata: { aml: "PASS" }
        }
      },
      $set: {
        current_state: "VALIDATED",
        last_state_changed_at: new Date(),
        updated_at: new Date()
      }
    },
    { session: session }
  );

  session.commitTransaction();
} catch (error) {
  session.abortTransaction();
  throw error;
} finally {
  session.endSession();
}

// ============================================================================
// IDEMPOTENCY Patterns
// ============================================================================

// Insert message with idempotency check (using upsert)
db.messages.updateOne(
  { external_ref: "BATCH_IDEMPOTENT_001" },
  {
    $setOnInsert: {
      external_ref: "BATCH_IDEMPOTENT_001",
      source_system: "System-A",
      current_state: "RECEIVED",
      received_at: new Date(),
      last_state_changed_at: new Date(),
      attributes: {},
      payment_ids: [],
      totals: { count: 0, by_currency: [] },
      created_at: new Date(),
      updated_at: new Date()
    }
  },
  { upsert: true }
);

// Insert message with idempotency check (update if exists)
db.messages.updateOne(
  { external_ref: "BATCH_IDEMPOTENT_002" },
  {
    $set: {
      source_system: "System-A",
      updated_at: new Date()
    },
    $setOnInsert: {
      external_ref: "BATCH_IDEMPOTENT_002",
      current_state: "RECEIVED",
      received_at: new Date(),
      last_state_changed_at: new Date(),
      attributes: {},
      payment_ids: [],
      totals: { count: 0, by_currency: [] },
      created_at: new Date()
    }
  },
  { upsert: true }
);

// Insert payment with idempotency check
db.payments.updateOne(
  { payment_ref: "PMT-IDEMPOTENT-001" },
  {
    $setOnInsert: {
      message_id: ObjectId("6755f0b2c3a9b2f3d4a30001"),
      payment_ref: "PMT-IDEMPOTENT-001",
      scheme: "FPS",
      amount: NumberDecimal("1000.00"),
      currency: "GBP",
      current_state: "RECEIVED",
      last_state_changed_at: new Date(),
      instructed_on: new Date(),
      debtor_snapshot: { display_name: "Debtor", identifiers: [] },
      creditor_snapshot: { display_name: "Creditor", identifiers: [] },
      state_history: [{
        seq_no: 1,
        from_state: null,
        to_state: "RECEIVED",
        actor: { type: "SYSTEM" },
        occurred_at: new Date(),
        metadata: {}
      }],
      route_steps: [],
      route_summary: {},
      attributes: {},
      created_at: new Date(),
      updated_at: new Date()
    }
  },
  { upsert: true }
);

// ============================================================================
// STATE TRANSITION Examples
// ============================================================================

// Transition message state (atomic update)
db.messages.updateOne(
  {
    _id: ObjectId("6755f0b2c3a9b2f3d4a30001"),
    current_state: "RECEIVED"
  },
  {
    $set: {
      current_state: "VALIDATED",
      last_state_changed_at: new Date(),
      updated_at: new Date()
    }
  }
);

// Transition payment state with state history logging
db.payments.updateOne(
  {
    _id: ObjectId("6755f0b2c3a9b2f3d4a40001"),
    current_state: "VALIDATED"
  },
  [
    {
      $set: {
        new_seq_no: {
          $ifNull: [
            { $add: [{ $max: "$state_history.seq_no" }, 1] },
            1
          ]
        }
      }
    },
    {
      $set: {
        state_history: {
          $concatArrays: [
            "$state_history",
            [
              {
                seq_no: "$new_seq_no",
                from_state: "$current_state",
                to_state: "ROUTED",
                actor: { type: "SYSTEM", id: "routing-svc" },
                occurred_at: new Date(),
                metadata: { corridor: "FPS:Direct" }
              }
            ]
          ]
        },
        current_state: "ROUTED",
        last_state_changed_at: new Date(),
        updated_at: new Date()
      }
    },
    {
      $unset: "new_seq_no"
    }
  ]
);

// ============================================================================
// ANALYTICS Queries
// ============================================================================

// Payment success rate by scheme
db.payments.aggregate([
  {
    $group: {
      _id: "$scheme",
      total_payments: { $sum: 1 },
      settled_count: {
        $sum: { $cond: [{ $eq: ["$current_state", "SETTLED"] }, 1, 0] }
      },
      rejected_count: {
        $sum: { $cond: [{ $eq: ["$current_state", "REJECTED"] }, 1, 0] }
      }
    }
  },
  {
    $project: {
      _id: 1,
      total_payments: 1,
      settled_count: 1,
      rejected_count: 1,
      success_rate_pct: {
        $multiply: [
          { $divide: ["$settled_count", "$total_payments"] },
          100
        ]
      }
    }
  },
  { $sort: { total_payments: -1 } }
]);

// Average payment processing time (from RECEIVED to SETTLED)
db.payments.aggregate([
  { $unwind: "$state_history" },
  {
    $group: {
      _id: "$_id",
      scheme: { $first: "$scheme" },
      received_time: {
        $min: {
          $cond: [
            { $eq: ["$state_history.to_state", "RECEIVED"] },
            "$state_history.occurred_at",
            null
          ]
        }
      },
      settled_time: {
        $min: {
          $cond: [
            { $eq: ["$state_history.to_state", "SETTLED"] },
            "$state_history.occurred_at",
            null
          ]
        }
      }
    }
  },
  {
    $match: {
      received_time: { $ne: null },
      settled_time: { $ne: null }
    }
  },
  {
    $project: {
      scheme: 1,
      processing_seconds: {
        $divide: [
          { $subtract: ["$settled_time", "$received_time"] },
          1000
        ]
      }
    }
  },
  {
    $group: {
      _id: "$scheme",
      avg_seconds: { $avg: "$processing_seconds" }
    }
  }
]);

// Payment volume by day
db.payments.aggregate([
  {
    $match: {
      created_at: {
        $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
      }
    }
  },
  {
    $group: {
      _id: {
        $dateToString: {
          format: "%Y-%m-%d",
          date: "$created_at"
        }
      },
      payment_count: { $sum: 1 },
      total_amount: { $sum: "$amount" },
      currencies: { $addToSet: "$currency" }
    }
  },
  {
    $project: {
      _id: 0,
      payment_date: "$_id",
      payment_count: 1,
      total_amount: 1,
      currency_count: { $size: "$currencies" }
    }
  },
  { $sort: { payment_date: -1 } }
]);

// Top debtors by payment volume
db.payments.aggregate([
  {
    $lookup: {
      from: "parties",
      localField: "debtor_id",
      foreignField: "_id",
      as: "debtor"
    }
  },
  { $unwind: { path: "$debtor", preserveNullAndEmptyArrays: true } },
  {
    $group: {
      _id: "$debtor_id",
      display_name: { $first: "$debtor.display_name" },
      payment_count: { $sum: 1 },
      total_amount: { $sum: "$amount" }
    }
  },
  { $sort: { total_amount: -1 } },
  { $limit: 10 }
]);

// Route step analysis
db.payments.aggregate([
  { $unwind: "$route_steps" },
  {
    $group: {
      _id: {
        role: "$route_steps.role",
        country_code: "$route_steps.institution_snapshot.country_code"
      },
      step_count: { $sum: 1 },
      payment_count: { $addToSet: "$_id" }
    }
  },
  {
    $project: {
      _id: 0,
      role: "$_id.role",
      country_code: "$_id.country_code",
      step_count: 1,
      payment_count: { $size: "$payment_count" }
    }
  },
  { $sort: { step_count: -1 } }
]);

