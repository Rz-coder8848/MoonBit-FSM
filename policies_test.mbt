///|
test "retry policy records bounded attempts and final error" {
  let builder : Builder[String, String, Unit] = Builder::new().transition_if(
    "Open",
    "Approve",
    "Closed",
    fn(_s, _e, _ctx) { false },
  )
  let engine = builder.build("Open", ())
  let report = engine.try_send_with_retry(
    "Approve",
    RetryPolicy::new(3, GuardOnly),
  )
  inspect(report.accepted, content="false")
  inspect(report.exhausted, content="true")
  inspect(report.attempts.length(), content="3")
  inspect(report.final_error is Some(GuardRejected), content="true")
  inspect(engine.metrics().attempted, content="3")
}

///|
test "retry policy succeeds after a first external failure" {
  let mut allowed = false
  let builder : Builder[String, String, Unit] = Builder::new().transition_if(
    "Open",
    "Approve",
    "Closed",
    fn(_s, _e, _ctx) { allowed },
  )
  let engine = builder.build("Open", ())
  let first = engine.try_send_with_retry(
    "Approve",
    RetryPolicy::new(1, GuardOnly),
  )
  inspect(first.accepted, content="false")
  allowed = true
  let second = engine.try_send_with_retry(
    "Approve",
    RetryPolicy::new(2, GuardOnly),
  )
  inspect(second.accepted, content="true")
  inspect(second.attempts.length(), content="1")
}

///|
test "budget stops an error storm and preserves order" {
  let builder : Builder[String, String, Unit] = Builder::new().transition(
    "Open", "Close", "Closed",
  )
  let engine = builder.build("Open", ())
  let report = engine.try_send_with_budget(
    ["Unknown", "StillUnknown", "Close"],
    0,
  )
  inspect(report.processed, content="1")
  inspect(report.rejected, content="1")
  inspect(report.stopped, content="true")
  inspect(engine.state(), content="Open")
}

///|
test "history summary exposes operational transition facts" {
  let builder : Builder[String, String, Unit] = Builder::new().transition_if(
    "Open",
    "Approve",
    "Closed",
    fn(_s, _e, _ctx) { true },
  )
  let engine = builder.build("Open", ())
  ignore(engine.try_send("Approve"))
  let summary = history_summary(engine.history())
  inspect(summary.transitions, content="1")
  inspect(summary.guarded_transitions, content="1")
  inspect(summary.distinct_states, content="2")
  inspect(summary.first_state is Some("Open"), content="true")
  inspect(summary.last_state is Some("Closed"), content="true")
}
