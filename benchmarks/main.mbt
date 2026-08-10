///|
struct Scenario {
  id : String
  family : String
  initial : String
  initial_context : Int
  events : Array[String]
  expected_state : String
  expected_successes : Int
  expected_rejections : Int
}

///|
fn approval_builder() -> @fsm.Builder[String, String, Int] {
  @fsm.Builder::new()
  .transition_do("Draft", "Submit", "Review.Pending", fn(_s, _e, ctx) {
    ctx + 1
  })
  .transition_if_do(
    "Review.Pending",
    "Approve",
    "Review.Approved",
    fn(_s, _e, ctx) { ctx >= 80 },
    fn(_s, _e, ctx) { ctx + 5 },
  )
  .transition("Review.Pending", "RequestChanges", "Review.Rework")
  .transition("Review.Pending", "Cancel", "Cancelled")
  .transition("Review.Pending", "Reject", "Review.Rejected")
  .transition_do("Review.Rework", "Resubmit", "Review.Pending", fn(
    _s,
    _e,
    ctx,
  ) {
    ctx + 20
  })
  .transition("Review.Rework", "Cancel", "Cancelled")
  .transition("Review.Rejected", "Escalate", "Error.Validation")
  .transition("Review.Approved", "Archive", "Closed")
}

///|
fn order_builder() -> @fsm.Builder[String, String, Int] {
  @fsm.Builder::new()
  .transition_do("Created", "Pay", "Paid", fn(_s, _e, ctx) { ctx + 1 })
  .transition_if("Paid", "Ship", "Shipped", fn(_s, _e, ctx) { ctx > 0 })
  .transition("Paid", "Cancel", "Cancelled")
  .transition("Shipped", "Deliver", "Delivered")
  .transition("Shipped", "Return", "Returned")
}

///|
fn device_builder() -> @fsm.Builder[String, String, Int] {
  @fsm.Builder::new()
  .transition("Offline", "Boot", "Ready")
  .transition("Ready", "Start", "Running")
  .transition("Running", "Stop", "Ready")
  .transition("Running", "Fault", "Error")
  .transition("Error", "Reset", "Ready")
}

///|
fn support_builder() -> @fsm.Builder[String, String, Int] {
  @fsm.Builder::new()
  .transition_do("Open", "Assign", "InProgress", fn(_s, _e, ctx) { ctx + 1 })
  .transition("InProgress", "Resolve", "Resolved")
  .transition("InProgress", "Escalate", "Escalated")
  .transition("Escalated", "Resolve", "Resolved")
  .transition("Resolved", "Reopen", "Open")
  .transition("Resolved", "Close", "Closed")
}

///|
fn builder_for(family : String) -> @fsm.Builder[String, String, Int] {
  if family == "approval" {
    approval_builder()
  } else if family == "order" {
    order_builder()
  } else if family == "device" {
    device_builder()
  } else {
    support_builder()
  }
}

///|
fn scenarios() -> Array[Scenario] {
  [
    {
      id: "approval-happy-path",
      family: "approval",
      initial: "Draft",
      initial_context: 90,
      events: ["Submit", "Approve", "Archive"],
      expected_state: "Closed",
      expected_successes: 3,
      expected_rejections: 0,
    },
    {
      id: "approval-guard-retry",
      family: "approval",
      initial: "Draft",
      initial_context: 60,
      events: [
        "Submit", "Approve", "RequestChanges", "Resubmit", "Approve", "Archive",
      ],
      expected_state: "Closed",
      expected_successes: 5,
      expected_rejections: 1,
    },
    {
      id: "approval-cancel",
      family: "approval",
      initial: "Draft",
      initial_context: 50,
      events: ["Submit", "Cancel"],
      expected_state: "Cancelled",
      expected_successes: 2,
      expected_rejections: 0,
    },
    {
      id: "approval-error-escalation",
      family: "approval",
      initial: "Draft",
      initial_context: 40,
      events: ["Submit", "Reject", "Escalate"],
      expected_state: "Error.Validation",
      expected_successes: 3,
      expected_rejections: 0,
    },
    {
      id: "approval-rework-loop",
      family: "approval",
      initial: "Draft",
      initial_context: 90,
      events: ["Submit", "RequestChanges", "Resubmit", "Approve", "Archive"],
      expected_state: "Closed",
      expected_successes: 5,
      expected_rejections: 0,
    },
    {
      id: "approval-blocked-then-recover",
      family: "approval",
      initial: "Draft",
      initial_context: 70,
      events: [
        "Submit", "Approve", "RequestChanges", "Resubmit", "Approve", "Archive",
      ],
      expected_state: "Closed",
      expected_successes: 5,
      expected_rejections: 1,
    },
    {
      id: "approval-reject-terminal",
      family: "approval",
      initial: "Draft",
      initial_context: 60,
      events: ["Submit", "Reject", "Escalate", "Approve"],
      expected_state: "Error.Validation",
      expected_successes: 3,
      expected_rejections: 1,
    },
    {
      id: "approval-rework-cancel",
      family: "approval",
      initial: "Draft",
      initial_context: 60,
      events: ["Submit", "RequestChanges", "Cancel", "Resubmit"],
      expected_state: "Cancelled",
      expected_successes: 3,
      expected_rejections: 1,
    },
    {
      id: "approval-pending-unknown",
      family: "approval",
      initial: "Draft",
      initial_context: 80,
      events: ["Submit", "Publish", "Cancel"],
      expected_state: "Cancelled",
      expected_successes: 2,
      expected_rejections: 1,
    },
    {
      id: "order-delivery",
      family: "order",
      initial: "Created",
      initial_context: 0,
      events: ["Pay", "Ship", "Deliver"],
      expected_state: "Delivered",
      expected_successes: 3,
      expected_rejections: 0,
    },
    {
      id: "order-cancel",
      family: "order",
      initial: "Created",
      initial_context: 0,
      events: ["Pay", "Cancel"],
      expected_state: "Cancelled",
      expected_successes: 2,
      expected_rejections: 0,
    },
    {
      id: "order-invalid-retry",
      family: "order",
      initial: "Created",
      initial_context: 0,
      events: ["Ship", "Pay", "Ship", "Return"],
      expected_state: "Returned",
      expected_successes: 3,
      expected_rejections: 1,
    },
    {
      id: "order-return-boundary",
      family: "order",
      initial: "Shipped",
      initial_context: 1,
      events: ["Return", "Deliver"],
      expected_state: "Returned",
      expected_successes: 1,
      expected_rejections: 1,
    },
    {
      id: "order-pay-then-deliver-invalid",
      family: "order",
      initial: "Created",
      initial_context: 0,
      events: ["Deliver", "Pay", "Ship", "Deliver"],
      expected_state: "Delivered",
      expected_successes: 3,
      expected_rejections: 1,
    },
    {
      id: "order-cancel-before-pay",
      family: "order",
      initial: "Created",
      initial_context: 0,
      events: ["Cancel", "Pay"],
      expected_state: "Paid",
      expected_successes: 1,
      expected_rejections: 1,
    },
    {
      id: "order-ship-without-pay",
      family: "order",
      initial: "Created",
      initial_context: 0,
      events: ["Ship", "Pay", "Ship", "Deliver"],
      expected_state: "Delivered",
      expected_successes: 3,
      expected_rejections: 1,
    },
    {
      id: "order-terminal-retry",
      family: "order",
      initial: "Created",
      initial_context: 0,
      events: ["Pay", "Cancel", "Deliver"],
      expected_state: "Cancelled",
      expected_successes: 2,
      expected_rejections: 1,
    },
    {
      id: "order-return-after-delivery",
      family: "order",
      initial: "Created",
      initial_context: 0,
      events: ["Pay", "Ship", "Deliver", "Return"],
      expected_state: "Delivered",
      expected_successes: 3,
      expected_rejections: 1,
    },
    {
      id: "device-start-stop",
      family: "device",
      initial: "Offline",
      initial_context: 0,
      events: ["Boot", "Start", "Stop"],
      expected_state: "Ready",
      expected_successes: 3,
      expected_rejections: 0,
    },
    {
      id: "device-fault-recovery",
      family: "device",
      initial: "Offline",
      initial_context: 0,
      events: ["Boot", "Start", "Fault", "Reset", "Start"],
      expected_state: "Running",
      expected_successes: 5,
      expected_rejections: 0,
    },
    {
      id: "device-invalid-boot",
      family: "device",
      initial: "Running",
      initial_context: 0,
      events: ["Boot", "Fault", "Reset", "Stop"],
      expected_state: "Ready",
      expected_successes: 2,
      expected_rejections: 2,
    },
    {
      id: "device-fault-loop",
      family: "device",
      initial: "Offline",
      initial_context: 0,
      events: [
        "Boot", "Start", "Fault", "Reset", "Start", "Fault", "Reset", "Start",
      ],
      expected_state: "Running",
      expected_successes: 8,
      expected_rejections: 0,
    },
    {
      id: "device-terminal-error-recovery",
      family: "device",
      initial: "Offline",
      initial_context: 0,
      events: ["Boot", "Start", "Fault", "Reset", "Start", "Fault", "Reset"],
      expected_state: "Ready",
      expected_successes: 7,
      expected_rejections: 0,
    },
    {
      id: "device-ready-unknown",
      family: "device",
      initial: "Offline",
      initial_context: 0,
      events: ["Boot", "Pause", "Start"],
      expected_state: "Running",
      expected_successes: 2,
      expected_rejections: 1,
    },
    {
      id: "device-error-invalid-reset",
      family: "device",
      initial: "Offline",
      initial_context: 0,
      events: ["Boot", "Start", "Fault", "Stop", "Reset"],
      expected_state: "Ready",
      expected_successes: 4,
      expected_rejections: 1,
    },
    {
      id: "support-resolution",
      family: "support",
      initial: "Open",
      initial_context: 0,
      events: ["Assign", "Resolve", "Close"],
      expected_state: "Closed",
      expected_successes: 3,
      expected_rejections: 0,
    },
    {
      id: "support-escalation",
      family: "support",
      initial: "Open",
      initial_context: 0,
      events: ["Assign", "Escalate", "Resolve"],
      expected_state: "Resolved",
      expected_successes: 3,
      expected_rejections: 0,
    },
    {
      id: "support-reopen",
      family: "support",
      initial: "Open",
      initial_context: 0,
      events: ["Assign", "Resolve", "Reopen", "Assign", "Resolve"],
      expected_state: "Resolved",
      expected_successes: 5,
      expected_rejections: 0,
    },
    {
      id: "support-unknown-event",
      family: "support",
      initial: "Open",
      initial_context: 0,
      events: ["Close", "Assign", "Resolve"],
      expected_state: "Resolved",
      expected_successes: 2,
      expected_rejections: 1,
    },
    {
      id: "support-escalate-reopen",
      family: "support",
      initial: "Open",
      initial_context: 0,
      events: [
        "Assign", "Escalate", "Resolve", "Reopen", "Assign", "Resolve", "Close",
      ],
      expected_state: "Closed",
      expected_successes: 7,
      expected_rejections: 0,
    },
    {
      id: "support-close-too-early",
      family: "support",
      initial: "Open",
      initial_context: 0,
      events: ["Close", "Assign", "Resolve"],
      expected_state: "Resolved",
      expected_successes: 2,
      expected_rejections: 1,
    },
    {
      id: "support-reopen-loop",
      family: "support",
      initial: "Open",
      initial_context: 0,
      events: [
        "Assign", "Resolve", "Reopen", "Assign", "Resolve", "Reopen", "Assign", "Resolve",
      ],
      expected_state: "Resolved",
      expected_successes: 8,
      expected_rejections: 0,
    },
  ]
}

///|
fn run_scenario(case : Scenario) -> Bool {
  let engine = builder_for(case.family).build(
    case.initial,
    case.initial_context,
  )
  let mut successes = 0
  let mut rejections = 0
  for event in case.events {
    match engine.try_send(event) {
      Ok(_) => successes += 1
      Err(_) => rejections += 1
    }
  }
  let passed = engine.state() == case.expected_state &&
    successes == case.expected_successes &&
    rejections == case.expected_rejections &&
    engine.history().length() == case.expected_successes &&
    engine.audit_log().length() == case.events.length()
  if !passed {
    println(
      "FAIL \{case.id}: state=\{engine.state()} successes=\{successes} rejections=\{rejections} history=\{engine.history().length()} audit=\{engine.audit_log().length()}",
    )
  }
  passed
}

///|
fn main {
  let cases = scenarios()
  let mut passed = 0
  for case in cases {
    if run_scenario(case) {
      passed += 1
    }
  }
  println("Workflow benchmark: \{passed}/\{cases.length()} scenarios passed")
  @fsm.assert_invariant(passed == cases.length(), "workflow benchmark mismatch")
}
