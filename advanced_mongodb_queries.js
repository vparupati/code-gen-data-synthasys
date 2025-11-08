// ============================================================================
// Advanced MongoDB Queries for Payment Processing Model
// ============================================================================
// Comprehensive examples of $unionWith, $lookup, aggregation pipelines,
// window functions, and analytical queries with descriptive field mappings
// ============================================================================
//
// IMPORTANT: This file demonstrates how natural language descriptions map to
// actual field paths. See column_mappings.md for complete mapping reference.
//
// Example mappings used in this file:
//   "payment amount" → amount
//   "transaction status" → current_state
//   "sender name" → debtor_snapshot.display_name or via $lookup to parties
//   "batch identifier" → external_ref (from messages collection)
//   "bank name" → legal_name (from institutions collection)
//   "processing duration" → calculated: last_state_changed_at - created_at
// ============================================================================

// Switch to payment_db
db = db.getSiblingDB('payment_db');

// ============================================================================
// UNION OPERATIONS ($unionWith)
// ============================================================================

// $unionWith: Combine payments from different schemes
// Natural Language: "Get all payment references from both FPS and SEPA schemes"
// Maps: payment reference → payment_ref, scheme → scheme
db.payments.aggregate([
  {
    $unionWith: {
      coll: "payments",
      pipeline: [
        { $match: { scheme: "SEPA" } },
        { $project: { transaction_reference: "$payment_ref", payment_method: "$scheme" } }
      ]
    }
  },
  { $match: { scheme: "FPS" } },
  { $project: { transaction_reference: "$payment_ref", payment_method: "$scheme" } },
  { $sort: { transaction_reference: 1 } }
]);

// Alternative: Combine using $facet for parallel processing
// Natural Language: "Get payment amounts from both settled and rejected transactions"
db.payments.aggregate([
  {
    $facet: {
      settled: [
        { $match: { current_state: "SETTLED" } },
        { $project: { payment_amount: "$amount", transaction_status: "$current_state" } }
      ],
      rejected: [
        { $match: { current_state: "REJECTED" } },
        { $project: { payment_amount: "$amount", transaction_status: "$current_state" } }
      ]
    }
  },
  { $project: { all_payments: { $concatArrays: ["$settled", "$rejected"] } } },
  { $unwind: "$all_payments" },
  { $replaceRoot: { newRoot: "$all_payments" } },
  { $sort: { payment_amount: -1 } }
]);

// $unionWith: Combine payment and message references
// Natural Language: "Get all unique identifiers from both payments and messages"
db.payments.aggregate([
  {
    $project: {
      identifier: "$payment_ref",
      source_type: "payment"
    }
  },
  {
    $unionWith: {
      coll: "messages",
      pipeline: [
        { $match: { external_ref: { $exists: true, $ne: null } } },
        { $project: { identifier: "$external_ref", source_type: "message" } }
      ]
    }
  },
  { $match: { identifier: { $ne: null } } },
  { $sort: { identifier: 1 } }
]);

// ============================================================================
// INTERSECTION OPERATIONS
// ============================================================================

// $setIntersection: Find common payment references
// Natural Language: "Find payment references that appear in both GBP and EUR transactions"
db.payments.aggregate([
  {
    $facet: {
      gbp_payments: [
        { $match: { currency: "GBP" } },
        { $project: { transaction_reference: "$payment_ref" } }
      ],
      eur_payments: [
        { $match: { currency: "EUR" } },
        { $project: { transaction_reference: "$payment_ref" } }
      ]
    }
  },
  {
    $project: {
      common_references: {
        $setIntersection: [
          "$gbp_payments.transaction_reference",
          "$eur_payments.transaction_reference"
        ]
      }
    }
  },
  { $unwind: "$common_references" },
  { $project: { transaction_reference: "$common_references" } }
]);

// Intersection: Parties that are both debtors and creditors
// Natural Language: "Find parties that are both debtors and creditors"
db.parties.aggregate([
  {
    $facet: {
      debtors: [
        { $match: { party_type: "DEBTOR" } },
        { $project: { party_name: "$display_name" } }
      ],
      creditors: [
        { $match: { party_type: "CREDITOR" } },
        { $project: { party_name: "$display_name" } }
      ]
    }
  },
  {
    $project: {
      common_parties: {
        $setIntersection: [
          "$debtors.party_name",
          "$creditors.party_name"
        ]
      }
    }
  },
  { $unwind: "$common_parties" },
  { $project: { party_name: "$common_parties" } }
]);

// ============================================================================
// SET DIFFERENCE OPERATIONS
// ============================================================================

// $setDifference: Payments in one state but not another
// Natural Language: "Find payment references that are SETTLED but were never REJECTED"
db.payments.aggregate([
  {
    $facet: {
      settled: [
        { $match: { current_state: "SETTLED" } },
        { $project: { transaction_reference: "$payment_ref" } }
      ],
      rejected: [
        { $match: { current_state: "REJECTED" } },
        { $project: { transaction_reference: "$payment_ref" } }
      ]
    }
  },
  {
    $project: {
      difference: {
        $setDifference: [
          "$settled.transaction_reference",
          "$rejected.transaction_reference"
        ]
      }
    }
  },
  { $unwind: "$difference" },
  { $project: { transaction_reference: "$difference" } }
]);

// ============================================================================
// LOOKUP OPERATIONS ($lookup)
// ============================================================================

// $lookup: Payments with their message details
// Natural Language: "Get payment amounts with their message batch identifiers"
// Maps: payment amount → amount, batch identifier → external_ref
db.payments.aggregate([
  {
    $lookup: {
      from: "messages",
      localField: "message_id",
      foreignField: "_id",
      as: "message"
    }
  },
  { $unwind: { path: "$message", preserveNullAndEmptyArrays: true } },
  {
    $project: {
      transaction_reference: "$payment_ref",
      payment_amount: "$amount",
      batch_identifier: "$message.external_ref",
      origin_system: "$message.source_system"
    }
  }
]);

// $lookup: Payments with debtor party information
// Natural Language: "Get sender names for all payments"
// Maps: sender name → display_name (via lookup)
db.payments.aggregate([
  {
    $lookup: {
      from: "parties",
      localField: "debtor_id",
      foreignField: "_id",
      as: "debtor_party"
    }
  },
  { $unwind: { path: "$debtor_party", preserveNullAndEmptyArrays: true } },
  {
    $project: {
      transaction_reference: "$payment_ref",
      payment_amount: "$amount",
      sender_name: "$debtor_party.display_name",
      sender_email: "$debtor_party.email"
    }
  }
]);

// Nested $lookup: Multi-collection join
// Natural Language: "Get payment details with sender bank name and BIC code"
// Maps: bank name → legal_name, bank code → bic (via nested lookups)
db.payments.aggregate([
  {
    $lookup: {
      from: "parties",
      localField: "debtor_id",
      foreignField: "_id",
      as: "debtor_party"
    }
  },
  { $unwind: { path: "$debtor_party", preserveNullAndEmptyArrays: true } },
  {
    $lookup: {
      from: "institutions",
      localField: "debtor_party.institution_id",
      foreignField: "_id",
      as: "debtor_institution"
    }
  },
  { $unwind: { path: "$debtor_institution", preserveNullAndEmptyArrays: true } },
  {
    $lookup: {
      from: "parties",
      localField: "creditor_id",
      foreignField: "_id",
      as: "creditor_party"
    }
  },
  { $unwind: { path: "$creditor_party", preserveNullAndEmptyArrays: true } },
  {
    $lookup: {
      from: "institutions",
      localField: "creditor_party.institution_id",
      foreignField: "_id",
      as: "creditor_institution"
    }
  },
  { $unwind: { path: "$creditor_institution", preserveNullAndEmptyArrays: true } },
  {
    $project: {
      transaction_reference: "$payment_ref",
      payment_amount: "$amount",
      transaction_currency: "$currency",
      sender_name: "$debtor_party.display_name",
      sender_bank_name: "$debtor_institution.legal_name",
      sender_bank_code: "$debtor_institution.bic",
      receiver_name: "$creditor_party.display_name",
      receiver_bank_name: "$creditor_institution.legal_name",
      receiver_bank_code: "$creditor_institution.bic"
    }
  }
]);

// $lookup with pipeline: Correlated subquery
// Natural Language: "Get payments with count of their state transition events"
db.payments.aggregate([
  {
    $lookup: {
      from: "payments",
      let: { payment_id: "$_id" },
      pipeline: [
        {
          $match: {
            $expr: { $eq: ["$_id", "$$payment_id"] }
          }
        },
        {
          $project: {
            event_count: { $size: { $ifNull: ["$state_history", []] } }
          }
        }
      ],
      as: "event_info"
    }
  },
  {
    $project: {
      transaction_reference: "$payment_ref",
      transaction_status: "$current_state",
      event_count: { $ifNull: [{ $arrayElemAt: ["$event_info.event_count", 0] }, { $size: { $ifNull: ["$state_history", []] } }] }
    }
  },
  { $sort: { event_count: -1 } }
]);

// ============================================================================
// AGGREGATION PIPELINES - GROUPING
// ============================================================================

// Basic $group: Payment count by scheme
// Natural Language: "Count transactions grouped by payment scheme"
db.payments.aggregate([
  {
    $group: {
      _id: "$scheme",
      transaction_count: { $sum: 1 },
      total_payment_amount: { $sum: "$amount" }
    }
  },
  {
    $project: {
      _id: 0,
      payment_method: "$_id",
      transaction_count: 1,
      total_payment_amount: 1
    }
  },
  { $sort: { total_payment_amount: -1 } }
]);

// $group with $match (HAVING equivalent)
// Natural Language: "Find payment schemes with average amount above 1000"
db.payments.aggregate([
  {
    $group: {
      _id: "$scheme",
      transaction_count: { $sum: 1 },
      average_payment_amount: { $avg: "$amount" }
    }
  },
  { $match: { average_payment_amount: { $gt: 1000 } } },
  {
    $project: {
      _id: 0,
      payment_method: "$_id",
      transaction_count: 1,
      average_payment_amount: { $round: ["$average_payment_amount", 2] }
    }
  },
  { $sort: { average_payment_amount: -1 } }
]);

// $group multiple fields
// Natural Language: "Analyze payments by scheme and currency combination"
db.payments.aggregate([
  {
    $group: {
      _id: {
        payment_method: "$scheme",
        transaction_currency: "$currency"
      },
      transaction_count: { $sum: 1 },
      total_amount: { $sum: "$amount" },
      average_amount: { $avg: "$amount" }
    }
  },
  {
    $project: {
      _id: 0,
      payment_method: "$_id.payment_method",
      transaction_currency: "$_id.transaction_currency",
      transaction_count: 1,
      total_amount: 1,
      average_amount: { $round: ["$average_amount", 2] }
    }
  },
  { $sort: { payment_method: 1, total_amount: -1 } }
]);

// $group with $addToSet: Unique values
// Natural Language: "Get unique currencies used in each payment scheme"
db.payments.aggregate([
  {
    $group: {
      _id: "$scheme",
      currencies_used: { $addToSet: "$currency" },
      transaction_count: { $sum: 1 }
    }
  },
  {
    $project: {
      _id: 0,
      payment_method: "$_id",
      currencies_used: 1,
      currency_count: { $size: "$currencies_used" },
      transaction_count: 1
    }
  }
]);

// ============================================================================
// AGGREGATION PIPELINES - FACET (Multiple Aggregations)
// ============================================================================

// $facet: Multiple aggregation paths
// Natural Language: "Get payment statistics by scheme and by currency in parallel"
db.payments.aggregate([
  {
    $facet: {
      by_scheme: [
        {
          $group: {
            _id: "$scheme",
            count: { $sum: 1 },
            total: { $sum: "$amount" }
          }
        },
        { $sort: { total: -1 } }
      ],
      by_currency: [
        {
          $group: {
            _id: "$currency",
            count: { $sum: 1 },
            total: { $sum: "$amount" }
          }
        },
        { $sort: { total: -1 } }
      ],
      overall: [
        {
          $group: {
            _id: null,
            total_count: { $sum: 1 },
            total_amount: { $sum: "$amount" },
            avg_amount: { $avg: "$amount" }
          }
        }
      ]
    }
  }
]);

// ============================================================================
// WINDOW FUNCTIONS ($setWindowFields)
// ============================================================================

// ROW_NUMBER: Rank payments by amount within each scheme
// Natural Language: "Rank payments by amount within each payment scheme"
db.payments.aggregate([
  {
    $setWindowFields: {
      partitionBy: "$scheme",
      sortBy: { amount: -1 },
      output: {
        rank_within_scheme: {
          $documentNumber: {}
        }
      }
    }
  },
  {
    $project: {
      transaction_reference: "$payment_ref",
      payment_method: "$scheme",
      payment_amount: "$amount",
      rank_within_scheme: 1
    }
  },
  { $sort: { payment_method: 1, rank_within_scheme: 1 } }
]);

// RANK: Rank payments with ties
// Natural Language: "Rank all payments by amount, handling ties"
db.payments.aggregate([
  {
    $setWindowFields: {
      sortBy: { amount: -1 },
      output: {
        payment_rank: {
          $rank: {}
        }
      }
    }
  },
  {
    $project: {
      transaction_reference: "$payment_ref",
      payment_amount: "$amount",
      payment_rank: 1
    }
  },
  { $sort: { payment_rank: 1 } }
]);

// DENSE_RANK: Rank without gaps
// Natural Language: "Rank payments by amount without gaps in ranking"
db.payments.aggregate([
  {
    $setWindowFields: {
      sortBy: { amount: -1 },
      output: {
        dense_rank: {
          $denseRank: {}
        }
      }
    }
  },
  {
    $project: {
      transaction_reference: "$payment_ref",
      payment_amount: "$amount",
      dense_rank: 1
    }
  }
]);

// LAG: Compare with previous payment
// Natural Language: "Compare each payment amount with the previous payment amount"
db.payments.aggregate([
  { $sort: { created_at: 1 } },
  {
    $setWindowFields: {
      sortBy: { created_at: 1 },
      output: {
        previous_payment_amount: {
          $shift: {
            output: "$amount",
            by: -1,
            default: null
          }
        }
      }
    }
  },
  {
    $project: {
      transaction_reference: "$payment_ref",
      payment_amount: "$amount",
      previous_payment_amount: 1,
      amount_difference: {
        $subtract: [
          "$amount",
          { $ifNull: ["$previous_payment_amount", 0] }
        ]
      }
    }
  }
]);

// LEAD: Compare with next payment
// Natural Language: "Compare each payment amount with the next payment amount"
db.payments.aggregate([
  { $sort: { created_at: 1 } },
  {
    $setWindowFields: {
      sortBy: { created_at: 1 },
      output: {
        next_payment_amount: {
          $shift: {
            output: "$amount",
            by: 1,
            default: null
          }
        }
      }
    }
  },
  {
    $project: {
      transaction_reference: "$payment_ref",
      payment_amount: "$amount",
      next_payment_amount: 1
    }
  }
]);

// SUM OVER: Running total
// Natural Language: "Calculate running total of payment amounts"
db.payments.aggregate([
  { $sort: { created_at: 1 } },
  {
    $setWindowFields: {
      sortBy: { created_at: 1 },
      output: {
        running_total: {
          $sum: "$amount"
        }
      }
    }
  },
  {
    $project: {
      transaction_reference: "$payment_ref",
      payment_amount: "$amount",
      transaction_creation_date: "$created_at",
      running_total: 1
    }
  }
]);

// AVG OVER: Moving average
// Natural Language: "Calculate moving average of payment amounts over last 10 payments"
db.payments.aggregate([
  { $sort: { created_at: 1 } },
  {
    $setWindowFields: {
      sortBy: { created_at: 1 },
      output: {
        moving_average_10: {
          $avg: "$amount",
          window: {
            documents: [-9, 0]
          }
        }
      }
    }
  },
  {
    $project: {
      transaction_reference: "$payment_ref",
      payment_amount: "$amount",
      moving_average_10: { $round: ["$moving_average_10", 2] }
    }
  }
]);

// PARTITION BY: Statistics within groups
// Natural Language: "Calculate payment statistics within each currency"
db.payments.aggregate([
  {
    $setWindowFields: {
      partitionBy: "$currency",
      output: {
        avg_for_currency: { $avg: "$amount" },
        min_for_currency: { $min: "$amount" },
        max_for_currency: { $max: "$amount" }
      }
    }
  },
  {
    $project: {
      transaction_reference: "$payment_ref",
      transaction_currency: "$currency",
      payment_amount: "$amount",
      avg_for_currency: { $round: ["$avg_for_currency", 2] },
      min_for_currency: 1,
      max_for_currency: 1
    }
  },
  { $sort: { transaction_currency: 1, payment_amount: -1 } }
]);

// ============================================================================
// ANALYTICAL QUERIES - TIME SERIES
// ============================================================================

// Payments by day
// Natural Language: "Get daily payment volume and totals"
db.payments.aggregate([
  {
    $project: {
      payment_date: {
        $dateToString: {
          format: "%Y-%m-%d",
          date: "$created_at"
        }
      },
      amount: 1
    }
  },
  {
    $group: {
      _id: "$payment_date",
      transaction_count: { $sum: 1 },
      total_payment_amount: { $sum: "$amount" },
      average_payment_amount: { $avg: "$amount" }
    }
  },
  {
    $project: {
      _id: 0,
      payment_date: "$_id",
      transaction_count: 1,
      total_payment_amount: 1,
      average_payment_amount: { $round: ["$average_payment_amount", 2] }
    }
  },
  { $sort: { payment_date: -1 } }
]);

// Payments by hour
// Natural Language: "Analyze payment volume by hour of day"
db.payments.aggregate([
  {
    $project: {
      hour_of_day: { $hour: "$created_at" },
      amount: 1
    }
  },
  {
    $group: {
      _id: "$hour_of_day",
      transaction_count: { $sum: 1 },
      total_payment_amount: { $sum: "$amount" }
    }
  },
  {
    $project: {
      _id: 0,
      hour_of_day: "$_id",
      transaction_count: 1,
      total_payment_amount: 1
    }
  },
  { $sort: { hour_of_day: 1 } }
]);

// Monthly trends
// Natural Language: "Get monthly payment statistics"
db.payments.aggregate([
  {
    $project: {
      payment_month: {
        $dateToString: {
          format: "%Y-%m",
          date: "$created_at"
        }
      },
      amount: 1,
      scheme: 1
    }
  },
  {
    $group: {
      _id: "$payment_month",
      transaction_count: { $sum: 1 },
      total_payment_amount: { $sum: "$amount" },
      scheme_count: { $addToSet: "$scheme" }
    }
  },
  {
    $project: {
      _id: 0,
      payment_month: "$_id",
      transaction_count: 1,
      total_payment_amount: 1,
      scheme_count: { $size: "$scheme_count" }
    }
  },
  { $sort: { payment_month: -1 } }
]);

// ============================================================================
// ANALYTICAL QUERIES - STATE TRANSITIONS
// ============================================================================

// State transition analysis
// Natural Language: "Analyze state transitions: count transitions from each state to each state"
db.payments.aggregate([
  { $unwind: "$state_history" },
  {
    $group: {
      _id: {
        source_state: "$state_history.from_state",
        target_state: "$state_history.to_state"
      },
      transition_count: { $sum: 1 }
    }
  },
  {
    $project: {
      _id: 0,
      source_state: "$_id.source_state",
      target_state: "$_id.target_state",
      transition_count: 1
    }
  },
  { $sort: { transition_count: -1 } }
]);

// Payment lifecycle analysis
// Natural Language: "Calculate average time spent in each payment state"
db.payments.aggregate([
  { $unwind: { path: "$state_history", includeArrayIndex: "seq_index" } },
  {
    $setWindowFields: {
      partitionBy: "$_id",
      sortBy: { seq_index: 1 },
      output: {
        next_occurred_at: {
          $shift: {
            output: "$state_history.occurred_at",
            by: 1
          }
        }
      }
    }
  },
  {
    $project: {
      state_name: "$state_history.from_state",
      duration_in_state: {
        $subtract: [
          { $ifNull: ["$next_occurred_at", "$last_state_changed_at"] },
          "$state_history.occurred_at"
        ]
      }
    }
  },
  {
    $match: {
      duration_in_state: { $ne: null },
      state_name: { $ne: null }
    }
  },
  {
    $group: {
      _id: "$state_name",
      state_occurrences: { $sum: 1 },
      avg_seconds_in_state: {
        $avg: {
          $divide: ["$duration_in_state", 1000]
        }
      },
      min_seconds_in_state: {
        $min: {
          $divide: ["$duration_in_state", 1000]
        }
      },
      max_seconds_in_state: {
        $max: {
          $divide: ["$duration_in_state", 1000]
        }
      }
    }
  },
  {
    $project: {
      _id: 0,
      state_name: "$_id",
      state_occurrences: 1,
      avg_seconds_in_state: { $round: ["$avg_seconds_in_state", 2] },
      min_seconds_in_state: { $round: ["$min_seconds_in_state", 2] },
      max_seconds_in_state: { $round: ["$max_seconds_in_state", 2] }
    }
  },
  { $sort: { avg_seconds_in_state: -1 } }
]);

// ============================================================================
// ANALYTICAL QUERIES - ROUTING ANALYSIS
// ============================================================================

// Route step analysis
// Natural Language: "Analyze routing patterns: count steps by role and country"
db.payments.aggregate([
  { $unwind: "$route_steps" },
  {
    $group: {
      _id: {
        routing_role: "$route_steps.role",
        institution_country: "$route_steps.institution_snapshot.country_code"
      },
      step_count: { $sum: 1 },
      payment_count: { $addToSet: "$_id" }
    }
  },
  {
    $project: {
      _id: 0,
      routing_role: "$_id.routing_role",
      institution_country: "$_id.institution_country",
      step_count: 1,
      payment_count: { $size: "$payment_count" }
    }
  },
  { $sort: { step_count: -1 } }
]);

// Average route length by scheme
// Natural Language: "Calculate average number of routing steps per payment scheme"
db.payments.aggregate([
  {
    $project: {
      payment_method: "$scheme",
      route_step_count: { $size: { $ifNull: ["$route_steps", []] } }
    }
  },
  {
    $group: {
      _id: "$payment_method",
      avg_route_steps: { $avg: "$route_step_count" },
      max_route_steps: { $max: "$route_step_count" },
      min_route_steps: { $min: "$route_step_count" }
    }
  },
  {
    $project: {
      _id: 0,
      payment_method: "$_id",
      avg_route_steps: { $round: ["$avg_route_steps", 2] },
      max_route_steps: 1,
      min_route_steps: 1
    }
  },
  { $sort: { avg_route_steps: -1 } }
]);

// ============================================================================
// COMPLEX FILTERING - CONDITIONAL LOGIC
// ============================================================================

// $cond: Categorize payment amounts
// Natural Language: "Categorize payments by amount ranges"
db.payments.aggregate([
  {
    $project: {
      transaction_reference: "$payment_ref",
      payment_amount: "$amount",
      payment_category: {
        $switch: {
          branches: [
            { case: { $lt: ["$amount", 100] }, then: "Small" },
            { case: { $lt: ["$amount", 1000] }, then: "Medium" },
            { case: { $lt: ["$amount", 10000] }, then: "Large" }
          ],
          default: "Very Large"
        }
      }
    }
  },
  { $sort: { payment_amount: -1 } }
]);

// $cond: Payment status description
// Natural Language: "Get human-readable payment status descriptions"
db.payments.aggregate([
  {
    $project: {
      transaction_reference: "$payment_ref",
      transaction_status: "$current_state",
      status_description: {
        $switch: {
          branches: [
            { case: { $eq: ["$current_state", "RECEIVED"] }, then: "Payment Received" },
            { case: { $eq: ["$current_state", "VALIDATED"] }, then: "Payment Validated" },
            { case: { $eq: ["$current_state", "SETTLED"] }, then: "Payment Settled" },
            { case: { $eq: ["$current_state", "REJECTED"] }, then: "Payment Rejected" },
            { case: { $eq: ["$current_state", "FAILED"] }, then: "Payment Failed" }
          ],
          default: "Unknown Status"
        }
      }
    }
  }
]);

// $cond with aggregation
// Natural Language: "Count payments by status category"
db.payments.aggregate([
  {
    $project: {
      status_category: {
        $cond: {
          if: { $in: ["$current_state", ["SETTLED", "SENT_TO_SCHEME"]] },
          then: "Success",
          else: {
            $cond: {
              if: { $in: ["$current_state", ["REJECTED", "FAILED"]] },
              then: "Failure",
              else: "In Progress"
            }
          }
        }
      },
      amount: 1
    }
  },
  {
    $group: {
      _id: "$status_category",
      transaction_count: { $sum: 1 },
      total_amount: { $sum: "$amount" }
    }
  },
  {
    $project: {
      _id: 0,
      status_category: "$_id",
      transaction_count: 1,
      total_amount: 1
    }
  }
]);

// ============================================================================
// COMPLEX FILTERING - COALESCE ($ifNull)
// ============================================================================

// $ifNull: Use snapshot or joined data
// Natural Language: "Get sender name, preferring snapshot data over joined party data"
db.payments.aggregate([
  {
    $lookup: {
      from: "parties",
      localField: "debtor_id",
      foreignField: "_id",
      as: "debtor_party"
    }
  },
  { $unwind: { path: "$debtor_party", preserveNullAndEmptyArrays: true } },
  {
    $project: {
      transaction_reference: "$payment_ref",
      sender_name: {
        $ifNull: [
          "$debtor_snapshot.display_name",
          {
            $ifNull: ["$debtor_party.display_name", "Unknown Sender"]
          }
        ]
      }
    }
  }
]);

// $ifNull: Default values
// Natural Language: "Get payment references with default for missing values"
db.payments.aggregate([
  {
    $project: {
      transaction_reference: {
        $ifNull: [
          "$payment_ref",
          { $concat: ["REF-", { $toString: "$_id" }] }
        ]
      },
      payment_amount: "$amount"
    }
  }
]);

// ============================================================================
// COMPLEX ANALYTICAL QUERIES
// ============================================================================

// Payment success rate by scheme
// Natural Language: "Calculate payment success rate grouped by payment scheme"
db.payments.aggregate([
  {
    $group: {
      _id: "$scheme",
      total_transactions: { $sum: 1 },
      settled_count: {
        $sum: {
          $cond: [{ $eq: ["$current_state", "SETTLED"] }, 1, 0]
        }
      },
      rejected_count: {
        $sum: {
          $cond: [{ $eq: ["$current_state", "REJECTED"] }, 1, 0]
        }
      }
    }
  },
  {
    $project: {
      _id: 0,
      payment_method: "$_id",
      total_transactions: 1,
      settled_count: 1,
      rejected_count: 1,
      success_rate_percent: {
        $round: [
          {
            $multiply: [
              {
                $divide: ["$settled_count", "$total_transactions"]
              },
              100
            ]
          },
          2
        ]
      }
    }
  },
  { $sort: { success_rate_percent: -1 } }
]);

// Top debtors by volume
// Natural Language: "Find top 10 senders by total payment volume"
db.payments.aggregate([
  {
    $lookup: {
      from: "parties",
      localField: "debtor_id",
      foreignField: "_id",
      as: "debtor_party"
    }
  },
  { $unwind: { path: "$debtor_party", preserveNullAndEmptyArrays: true } },
  {
    $group: {
      _id: "$debtor_party._id",
      sender_name: { $first: "$debtor_party.display_name" },
      transaction_count: { $sum: 1 },
      total_payment_amount: { $sum: "$amount" },
      average_payment_amount: { $avg: "$amount" }
    }
  },
  {
    $project: {
      _id: 0,
      sender_name: 1,
      transaction_count: 1,
      total_payment_amount: 1,
      average_payment_amount: { $round: ["$average_payment_amount", 2] }
    }
  },
  { $sort: { total_payment_amount: -1 } },
  { $limit: 10 }
]);

// Payment processing time analysis
// Natural Language: "Analyze payment processing times from creation to settlement"
db.payments.aggregate([
  {
    $project: {
      transaction_reference: "$payment_ref",
      payment_method: "$scheme",
      creation_time: "$created_at",
      settlement_event: {
        $arrayElemAt: [
          {
            $filter: {
              input: "$state_history",
              as: "event",
              cond: { $eq: ["$$event.to_state", "SETTLED"] }
            }
          },
          0
        ]
      }
    }
  },
  {
    $match: {
      settlement_event: { $ne: null }
    }
  },
  {
    $project: {
      transaction_reference: 1,
      payment_method: 1,
      creation_time: 1,
      settlement_time: "$settlement_event.occurred_at",
      processing_seconds: {
        $divide: [
          {
            $subtract: [
              "$settlement_event.occurred_at",
              "$created_at"
            ]
          },
          1000
        ]
      }
    }
  },
  {
    $group: {
      _id: "$payment_method",
      settled_count: { $sum: 1 },
      avg_processing_seconds: { $avg: "$processing_seconds" },
      min_processing_seconds: { $min: "$processing_seconds" },
      max_processing_seconds: { $max: "$processing_seconds" }
    }
  },
  {
    $project: {
      _id: 0,
      payment_method: "$_id",
      settled_count: 1,
      avg_processing_seconds: { $round: ["$avg_processing_seconds", 2] },
      min_processing_seconds: { $round: ["$min_processing_seconds", 2] },
      max_processing_seconds: { $round: ["$max_processing_seconds", 2] }
    }
  },
  { $sort: { avg_processing_seconds: 1 } }
]);

// Message batch analysis
// Natural Language: "Analyze message batches: count, totals, and success rates"
db.messages.aggregate([
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
      batch_identifier: "$external_ref",
      origin_system: "$source_system",
      declared_count: "$totals.count",
      actual_payment_count: { $size: "$payments" },
      total_batch_amount: { $sum: "$payments.amount" },
      settled_count: {
        $size: {
          $filter: {
            input: "$payments",
            as: "p",
            cond: { $eq: ["$$p.current_state", "SETTLED"] }
          }
        }
      }
    }
  },
  {
    $project: {
      batch_identifier: 1,
      origin_system: 1,
      declared_count: 1,
      actual_payment_count: 1,
      total_batch_amount: 1,
      settled_count: 1,
      batch_success_rate: {
        $round: [
          {
            $multiply: [
              {
                $divide: [
                  "$settled_count",
                  { $ifNull: ["$actual_payment_count", 1] }
                ]
              },
              100
            ]
          },
          2
        ]
      }
    }
  },
  { $sort: { total_batch_amount: -1 } }
]);

// Institution routing analysis
// Natural Language: "Analyze which institutions are used most in payment routing"
db.payments.aggregate([
  { $unwind: "$route_steps" },
  {
    $lookup: {
      from: "institutions",
      localField: "route_steps.institution_id",
      foreignField: "_id",
      as: "institution"
    }
  },
  { $unwind: { path: "$institution", preserveNullAndEmptyArrays: true } },
  {
    $group: {
      _id: {
        bank_id: { $ifNull: ["$institution._id", "$route_steps.institution_snapshot.legal_name"] },
        bank_name: { $ifNull: ["$institution.legal_name", "$route_steps.institution_snapshot.legal_name"] },
        bank_code: { $ifNull: ["$institution.bic", "$route_steps.institution_snapshot.bic"] },
        institution_country: { $ifNull: ["$institution.country_code", "$route_steps.institution_snapshot.country_code"] }
      },
      routing_occurrences: { $sum: 1 },
      unique_payment_count: { $addToSet: "$_id" },
      roles_played: { $addToSet: "$route_steps.role" }
    }
  },
  {
    $project: {
      _id: 0,
      bank_name: "$_id.bank_name",
      bank_code: "$_id.bank_code",
      institution_country: "$_id.institution_country",
      routing_occurrences: 1,
      unique_payment_count: { $size: "$unique_payment_count" },
      roles_played: { $size: "$roles_played" }
    }
  },
  { $sort: { routing_occurrences: -1 } }
]);

// ============================================================================
// NATURAL LANGUAGE TO FIELD MAPPING EXAMPLES
// ============================================================================
// These examples demonstrate how natural language descriptions are mapped
// to actual MongoDB field paths. This helps train SLMs to understand
// that queries can be expressed in multiple ways.
// ============================================================================

// Example 1: Simple field access with natural language
// Natural Language: "Show me the money transferred for each transaction"
// Maps: "money transferred" → amount
db.payments.aggregate([
  {
    $project: {
      transaction_reference: "$payment_ref",
      money_transferred: "$amount"
    }
  }
]);

// Example 2: Status field with alternative descriptions
// Natural Language: "Get the current status of all payments"
// Maps: "current status" → current_state, "transaction status" → current_state
db.payments.aggregate([
  {
    $project: {
      transaction_reference: "$payment_ref",
      current_status: "$current_state",
      transaction_status: "$current_state"
    }
  }
]);

// Example 3: Nested field access
// Natural Language: "Get the name of the person sending money"
// Maps: "name of person sending money" → debtor_snapshot.display_name
db.payments.aggregate([
  {
    $project: {
      transaction_reference: "$payment_ref",
      sender_name: "$debtor_snapshot.display_name",
      name_of_person_sending_money: "$debtor_snapshot.display_name"
    }
  }
]);

// Example 4: Calculated field from natural language
// Natural Language: "How long did it take to process each payment?"
// Maps: "processing time" → calculated: last_state_changed_at - created_at
db.payments.aggregate([
  {
    $project: {
      transaction_reference: "$payment_ref",
      processing_time_seconds: {
        $divide: [
          { $subtract: ["$last_state_changed_at", "$created_at"] },
          1000
        ]
      },
      how_long_to_process: {
        $divide: [
          { $subtract: ["$last_state_changed_at", "$created_at"] },
          1000
        ]
      }
    }
  }
]);

// Example 5: $lookup required for natural language description
// Natural Language: "What is the name of the bank that sent the payment?"
// Maps: "bank that sent payment" → requires $lookup: parties -> institutions -> legal_name
db.payments.aggregate([
  {
    $lookup: {
      from: "parties",
      localField: "debtor_id",
      foreignField: "_id",
      as: "debtor_party"
    }
  },
  { $unwind: { path: "$debtor_party", preserveNullAndEmptyArrays: true } },
  {
    $lookup: {
      from: "institutions",
      localField: "debtor_party.institution_id",
      foreignField: "_id",
      as: "sender_institution"
    }
  },
  { $unwind: { path: "$sender_institution", preserveNullAndEmptyArrays: true } },
  {
    $project: {
      transaction_reference: "$payment_ref",
      bank_that_sent_payment: "$sender_institution.legal_name",
      sender_bank_name: "$sender_institution.legal_name"
    }
  }
]);

// Example 6: Multiple natural language descriptions for same field
// Natural Language: "Get payment currency, transaction currency, and currency type"
// Maps: All three → currency field
db.payments.aggregate([
  {
    $project: {
      transaction_reference: "$payment_ref",
      payment_currency: "$currency",
      transaction_currency: "$currency",
      currency_type: "$currency"
    }
  }
]);

// Example 7: Natural language with aggregation
// Natural Language: "What is the total money moved through each payment scheme?"
// Maps: "money moved" → amount, "payment scheme" → scheme
db.payments.aggregate([
  {
    $group: {
      _id: "$scheme",
      total_money_moved: { $sum: "$amount" },
      total_amount: { $sum: "$amount" }
    }
  },
  {
    $project: {
      _id: 0,
      payment_scheme: "$_id",
      total_money_moved: 1,
      total_amount: 1
    }
  }
]);

// Example 8: Natural language describing a relationship
// Natural Language: "Show payments with their message batch information"
// Maps: "message batch information" → requires $lookup to messages collection
db.payments.aggregate([
  {
    $lookup: {
      from: "messages",
      localField: "message_id",
      foreignField: "_id",
      as: "message"
    }
  },
  { $unwind: { path: "$message", preserveNullAndEmptyArrays: true } },
  {
    $project: {
      transaction_reference: "$payment_ref",
      payment_amount: "$amount",
      message_batch_identifier: "$message.external_ref",
      message_batch_source: "$message.source_system"
    }
  }
]);

// Example 9: Natural language with time-based calculations
// Natural Language: "When was each payment created and how many days ago was that?"
// Maps: "when created" → created_at, "days ago" → calculated
db.payments.aggregate([
  {
    $project: {
      transaction_reference: "$payment_ref",
      when_created: "$created_at",
      days_ago: {
        $divide: [
          { $subtract: [new Date(), "$created_at"] },
          86400000
        ]
      }
    }
  }
]);

// Example 10: Natural language describing complex relationships
// Natural Language: "Show the complete payment flow: sender bank, receiver bank, and routing method"
// Maps: Requires multiple $lookups and nested field access
db.payments.aggregate([
  {
    $lookup: {
      from: "parties",
      localField: "debtor_id",
      foreignField: "_id",
      as: "debtor_party"
    }
  },
  { $unwind: { path: "$debtor_party", preserveNullAndEmptyArrays: true } },
  {
    $lookup: {
      from: "institutions",
      localField: "debtor_party.institution_id",
      foreignField: "_id",
      as: "debtor_institution"
    }
  },
  { $unwind: { path: "$debtor_institution", preserveNullAndEmptyArrays: true } },
  {
    $lookup: {
      from: "parties",
      localField: "creditor_id",
      foreignField: "_id",
      as: "creditor_party"
    }
  },
  { $unwind: { path: "$creditor_party", preserveNullAndEmptyArrays: true } },
  {
    $lookup: {
      from: "institutions",
      localField: "creditor_party.institution_id",
      foreignField: "_id",
      as: "creditor_institution"
    }
  },
  { $unwind: { path: "$creditor_institution", preserveNullAndEmptyArrays: true } },
  {
    $project: {
      transaction_reference: "$payment_ref",
      sender_bank: "$debtor_institution.legal_name",
      receiver_bank: "$creditor_institution.legal_name",
      routing_method: "$route_summary.method"
    }
  }
]);

