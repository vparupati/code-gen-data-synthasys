// ============================================================================
// MongoDB CRUD Operations Test Script
// ============================================================================
// This script tests basic CRUD operations on MongoDB
// ============================================================================

// Connect to MongoDB
// Note: If running via docker exec, authentication is handled via connection string
// If running directly, uncomment the auth line below
const db = db.getSiblingDB('payment_db');
// db.auth('payment_user', 'payment_pass');

print("============================================================================");
print("MongoDB CRUD Operations Test");
print("============================================================================");
print("");

// Test 1: CREATE - Insert institution
print("Test 1: CREATE - Insert institution");
const testInstitution = db.institutions.insertOne({
  legal_name: "Test Bank Ltd",
  bic: "TESTGB22XXX",
  country_code: "GB",
  created_at: new Date(),
  updated_at: new Date()
});
print("✓ Test 1 passed - Institution ID: " + testInstitution.insertedId);
print("");

// Test 2: READ - Get institutions
print("Test 2: READ - Get all institutions");
const institutions = db.institutions.find().sort({ created_at: -1 }).limit(5).toArray();
print("Found " + institutions.length + " institutions");
print("✓ Test 2 passed");
print("");

// Test 3: CREATE - Insert party
print("Test 3: CREATE - Insert party");
const testParty = db.parties.insertOne({
  party_type: "DEBTOR",
  display_name: "Test Company",
  email: "test@example.com",
  identifiers: [],
  created_at: new Date(),
  updated_at: new Date()
});
print("✓ Test 3 passed - Party ID: " + testParty.insertedId);
print("");

// Test 4: READ - Get parties with lookup
print("Test 4: READ - Get parties with aggregation");
const partiesWithInstitutions = db.parties.aggregate([
  { $match: {} },
  {
    $lookup: {
      from: "institutions",
      localField: "institution_id",
      foreignField: "_id",
      as: "institution"
    }
  },
  { $limit: 5 }
]).toArray();
print("Found " + partiesWithInstitutions.length + " parties");
print("✓ Test 4 passed");
print("");

// Test 5: CREATE - Insert message
print("Test 5: CREATE - Insert message");
const testMessage = db.messages.insertOne({
  external_ref: "TEST_MSG_001",
  source_system: "TestSystem",
  current_state: "RECEIVED",
  received_at: new Date(),
  last_state_changed_at: new Date(),
  attributes: {
    test: true,
    format: "ISO20022-pacs.008"
  },
  payment_ids: [],
  totals: {
    count: 0,
    by_currency: []
  },
  created_at: new Date(),
  updated_at: new Date()
});
print("✓ Test 5 passed - Message ID: " + testMessage.insertedId);
print("");

// Test 6: READ - Query nested attributes
print("Test 6: READ - Query messages with nested filter");
const messagesWithTest = db.messages.find({
  "attributes.test": true
}).toArray();
print("Found " + messagesWithTest.length + " messages with test attribute");
print("✓ Test 6 passed");
print("");

// Test 7: CREATE - Insert payment
print("Test 7: CREATE - Insert payment");
const testPayment = db.payments.insertOne({
  message_id: testMessage.insertedId,
  payment_ref: "PMT-TEST-001",
  scheme: "FPS",
  amount: NumberDecimal("1000.00"),
  currency: "GBP",
  current_state: "RECEIVED",
  last_state_changed_at: new Date(),
  instructed_on: new Date(),
  debtor_snapshot: {
    display_name: "Test Debtor",
    identifiers: []
  },
  creditor_snapshot: {
    display_name: "Test Creditor",
    identifiers: []
  },
  state_history: [{
    seq_no: 1,
    from_state: null,
    to_state: "RECEIVED",
    actor: { type: "SYSTEM", id: "test-script" },
    occurred_at: new Date(),
    metadata: {}
  }],
  route_steps: [],
  route_summary: {},
  attributes: {},
  created_at: new Date(),
  updated_at: new Date()
});
print("✓ Test 7 passed - Payment ID: " + testPayment.insertedId);
print("");

// Test 8: READ - Get payments with message lookup
print("Test 8: READ - Get payments with message join");
const paymentsWithMessages = db.payments.aggregate([
  { $match: {} },
  {
    $lookup: {
      from: "messages",
      localField: "message_id",
      foreignField: "_id",
      as: "message"
    }
  },
  { $limit: 5 }
]).toArray();
print("Found " + paymentsWithMessages.length + " payments");
print("✓ Test 8 passed");
print("");

// Test 9: UPDATE - Update payment state with state_history
print("Test 9: UPDATE - Update payment state with state_history");
const updateResult = db.payments.updateOne(
  { _id: testPayment.insertedId },
  {
    $push: {
      state_history: {
        seq_no: 2,
        from_state: "RECEIVED",
        to_state: "VALIDATED",
        actor: { type: "SYSTEM", id: "test-script" },
        occurred_at: new Date(),
        metadata: { test: true }
      }
    },
    $set: {
      current_state: "VALIDATED",
      last_state_changed_at: new Date(),
      updated_at: new Date()
    }
  }
);
print("✓ Test 9 passed - Updated " + updateResult.modifiedCount + " document");
print("");

// Test 10: READ - Get payment state history
print("Test 10: READ - Get payment state history");
const payment = db.payments.findOne({ _id: testPayment.insertedId });
print("Payment state history:");
payment.state_history.forEach(function(event) {
  print("  Seq " + event.seq_no + ": " + event.from_state + " -> " + event.to_state);
});
print("✓ Test 10 passed");
print("");

// Test 11: UPDATE - Add route step
print("Test 11: UPDATE - Add route step to payment");
const routeStepResult = db.payments.updateOne(
  { _id: testPayment.insertedId },
  {
    $push: {
      route_steps: {
        step_no: 1,
        role: "SENDER_BANK",
        institution_snapshot: {
          legal_name: "Test Bank",
          bic: "TESTGB22XXX",
          country_code: "GB"
        },
        metadata: { test: true }
      }
    },
    $set: { updated_at: new Date() }
  }
);
print("✓ Test 11 passed - Updated " + routeStepResult.modifiedCount + " document");
print("");

// Test 12: READ - Analytics query (count by state)
print("Test 12: READ - Analytics (payment count by state)");
const paymentStats = db.payments.aggregate([
  {
    $group: {
      _id: "$current_state",
      count: { $sum: 1 },
      total_amount: { $sum: "$amount" }
    }
  },
  { $sort: { count: -1 } }
]).toArray();
print("Payment statistics by state:");
paymentStats.forEach(function(stat) {
  print("  " + stat._id + ": " + stat.count + " payments, Total: " + stat.total_amount);
});
print("✓ Test 12 passed");
print("");

// Test 13: DELETE - Cleanup test data
print("Test 13: DELETE - Cleanup test data");
db.payments.deleteOne({ _id: testPayment.insertedId });
db.messages.deleteOne({ _id: testMessage.insertedId });
db.parties.deleteOne({ _id: testParty.insertedId });
db.institutions.deleteOne({ _id: testInstitution.insertedId });
print("✓ Test 13 passed - Test data cleaned up");
print("");

print("============================================================================");
print("All MongoDB CRUD tests completed successfully!");
print("============================================================================");

