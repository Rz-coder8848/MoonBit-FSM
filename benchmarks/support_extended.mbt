///|
/// Additional support scenarios cover long-running tickets and operator safety.
fn extend_scenarios(cases : Array[Scenario]) -> Array[Scenario] {
  cases.push({
    id: "support-triage-assignment-resolution",
    family: "support",
    initial: "Open",
    initial_context: 0,
    events: ["Triage", "Assign", "Resolve"],
    expected_state: "Resolved",
    expected_successes: 3,
    expected_rejections: 0,
  })
  cases.push({
    id: "support-request-customer-reply",
    family: "support",
    initial: "Open",
    initial_context: 0,
    events: ["Triage", "Assign", "RequestInfo", "CustomerReply", "Resolve"],
    expected_state: "Resolved",
    expected_successes: 5,
    expected_rejections: 0,
  })
  cases.push({
    id: "support-escalation-resolution",
    family: "support",
    initial: "Open",
    initial_context: 0,
    events: ["Triage", "Assign", "Escalate", "Resolve"],
    expected_state: "Resolved",
    expected_successes: 4,
    expected_rejections: 0,
  })
  cases.push({
    id: "support-escalation-reopen-close",
    family: "support",
    initial: "Open",
    initial_context: 0,
    events: [
      "Triage", "Assign", "Escalate", "Resolve", "Reopen", "Assign", "Resolve", "Close",
    ],
    expected_state: "Closed",
    expected_successes: 8,
    expected_rejections: 0,
  })
  cases.push({
    id: "support-cancel-before-triage",
    family: "support",
    initial: "Open",
    initial_context: 0,
    events: ["Cancel", "Triage"],
    expected_state: "Cancelled",
    expected_successes: 1,
    expected_rejections: 1,
  })
  cases.push({
    id: "support-double-cancel",
    family: "support",
    initial: "Open",
    initial_context: 0,
    events: ["Cancel", "Cancel"],
    expected_state: "Cancelled",
    expected_successes: 1,
    expected_rejections: 1,
  })
  cases.push({
    id: "support-waiting-unknown-reply",
    family: "support",
    initial: "Open",
    initial_context: 0,
    events: [
      "Triage", "Assign", "CustomerReply", "RequestInfo", "CustomerReply", "Resolve",
    ],
    expected_state: "Resolved",
    expected_successes: 5,
    expected_rejections: 1,
  })
  cases.push({
    id: "support-resolve-before-update",
    family: "support",
    initial: "Open",
    initial_context: 0,
    events: ["Triage", "Assign", "Resolve"],
    expected_state: "Resolved",
    expected_successes: 3,
    expected_rejections: 0,
  })
  cases.push({
    id: "support-reopen-after-close",
    family: "support",
    initial: "Open",
    initial_context: 0,
    events: ["Triage", "Assign", "Resolve", "Close", "Reopen"],
    expected_state: "Closed",
    expected_successes: 4,
    expected_rejections: 1,
  })
  cases.push({
    id: "support-escalate-without-assignment",
    family: "support",
    initial: "Open",
    initial_context: 0,
    events: ["Triage", "Escalate", "Assign", "Escalate", "Resolve"],
    expected_state: "Resolved",
    expected_successes: 4,
    expected_rejections: 1,
  })
  cases.push({
    id: "support-long-reopen-loop",
    family: "support",
    initial: "Open",
    initial_context: 0,
    events: [
      "Triage", "Assign", "Resolve", "Reopen", "Assign", "Resolve", "Reopen", "Assign",
      "Resolve", "Close",
    ],
    expected_state: "Closed",
    expected_successes: 10,
    expected_rejections: 0,
  })
  cases.push({
    id: "support-terminal-event-storm",
    family: "support",
    initial: "Open",
    initial_context: 0,
    events: [
      "Triage", "Assign", "Resolve", "Close", "Resolve", "Assign", "Cancel",
    ],
    expected_state: "Closed",
    expected_successes: 4,
    expected_rejections: 3,
  })
  cases
}
