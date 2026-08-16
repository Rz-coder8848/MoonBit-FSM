///|
fn test_builder() -> @fsm.Builder[String, String, IncidentContext] {
  incident_builder()
}

///|
test "incident response completes normal path" {
  let engine = test_builder().build("Detected", incident("T-1", "api", 2))
  let report = engine.try_send_all([
    "Acknowledge", "Diagnose", "Mitigate", "Verify",
  ])
  inspect(report.complete, content="true")
  inspect(engine.state(), content="Resolved")
  inspect(engine.context().responders, content="1")
  inspect(engine.context().mitigations, content="1")
  inspect(engine.context().customer_impact, content="false")
}

///|
test "incident escalation requires commander before diagnosis" {
  let engine = test_builder().build("Detected", incident("T-2", "db", 3))
  ignore(engine.try_send("Acknowledge"))
  ignore(engine.try_send("Escalate"))
  inspect(engine.state(), content="Escalated")
  inspect(
    engine.try_send("Diagnose") is Err(EventNotHandledInCurrentState),
    content="true",
  )
  ignore(engine.try_send("AssignCommander"))
  inspect(engine.state(), content="Investigating")
}

///|
test "incident rollback restores the pre-recovery checkpoint" {
  let engine = test_builder().build("Detected", incident("T-3", "web", 1))
  ignore(engine.try_send_all(["Acknowledge", "Diagnose", "Mitigate"]))
  let snapshot = engine.checkpoint()
  ignore(engine.try_send("Verify"))
  ignore(engine.try_send("Reopen"))
  ignore(engine.try_send("Rollback"))
  engine.restore(snapshot)
  inspect(engine.state(), content="Monitoring")
  inspect(engine.history().length(), content="3")
  inspect(engine.context().mitigations, content="1")
}

///|
test "incident journal and SLA are linked to audit evidence" {
  let engine = test_builder().build("Detected", incident("T-4", "queue", 2))
  ignore(engine.try_send("Acknowledge"))
  ignore(engine.try_send("Unknown"))
  let journal = @fsm.WorkflowJournal::new()
  inspect(journal.append_audit("T-4", engine.audit_log()), content="2")
  inspect(journal.count_level(Info), content="1")
  inspect(journal.count_level(Error), content="1")
  let evaluation = @fsm.evaluate_sla({ max_steps: 1, max_escalations: 0 }, 2, 0)
  inspect(evaluation.breached, content="true")
  inspect(@fsm.sla_status(evaluation), content="BREACHED")
}

///|
test "incident graph has recovery cycle and terminal closure" {
  let summary = @fsm.graph_summary(test_builder(), "Detected")
  inspect(summary.state_count, content="8")
  inspect(summary.transition_count, content="11")
  inspect(summary.has_cycle, content="true")
  inspect(summary.terminal_states.length(), content="1")
  inspect(summary.branching_states.length(), content="4")
}

///|
test "runbook review identifies the next owner and completion percent" {
  let runbook = runbook_for_severity(3)
  let engine = test_builder().build("Detected", incident("T-5", "api", 3))
  ignore(engine.try_send("Acknowledge"))
  let review = review_runbook(runbook, engine.history(), 3)
  inspect(review.required_total, content="6")
  inspect(review.required_completed, content="1")
  inspect(review.complete, content="false")
  inspect(review.escalation_required, content="true")
  inspect(review.next_owner is Some("incident-commander"), content="true")
  inspect(runbook_completion_percent(runbook, engine.history()), content="16")
  inspect(
    handover_message(review),
    content="Pending required action owned by incident-commander",
  )
}

///|
test "runbook owners and event inventory preserve operator order" {
  let runbook = runbook_for_severity(2)
  let owners = runbook_owners(runbook)
  let events = runbook_events(runbook)
  inspect(owners.length(), content="3")
  inspect(owners[0], content="on-call")
  inspect(owners[1], content="service-owner")
  inspect(owners[2], content="observability")
  inspect(events.length(), content="5")
  inspect(runbook_has_event(runbook, "Mitigate"), content="true")
  inspect(runbook_has_event(runbook, "Unknown"), content="false")
}

///|
test "runbook ownership and closure gate support handover review" {
  let runbook = runbook_for_severity(2)
  let engine = test_builder().build("Detected", incident("T-6", "api", 2))
  ignore(engine.try_send_all(["Acknowledge", "Diagnose"]))
  let owner_steps = steps_for_owner(runbook, "service-owner")
  inspect(owner_steps.length(), content="3")
  inspect(
    pending_steps_for_owner(runbook, engine.history(), "service-owner"),
    content="1",
  )
  inspect(
    first_event_for_owner(runbook, "service-owner") is Some("Diagnose"),
    content="true",
  )
  let review = review_runbook(runbook, engine.history(), 2)
  inspect(review_line(review), content="PENDING 2/4 NORMAL")
  let journal = @fsm.WorkflowJournal::new()
  ignore(journal.error("T-6", "Mitigating", "Verify", "not verified"))
  inspect(safe_to_close(review, journal), content="false")
  ignore(journal.acknowledge_ticket("T-6"))
  inspect(safe_to_close(review, journal), content="false")
}

///|
test "completed runbook reports closure readiness" {
  let runbook = runbook_for_severity(1)
  let engine = test_builder().build("Detected", incident("T-8", "cdn", 1))
  ignore(engine.try_send_all(["Acknowledge", "Diagnose", "Mitigate", "Verify"]))
  let review = review_runbook(runbook, engine.history(), 1)
  inspect(review.complete, content="true")
  inspect(review_line(review), content="COMPLETE 3/3 NORMAL")
  inspect(
    runbook_progress(runbook, engine.history()),
    content="SEV-3 standard response: 3/3 required steps",
  )
  let journal = @fsm.WorkflowJournal::new()
  inspect(safe_to_close(review, journal), content="true")
  inspect(
    handover_message(review),
    content="Runbook complete; response may enter closure review",
  )
  inspect(
    owner_has_pending(runbook, engine.history(), "service-owner"),
    content="false",
  )
  inspect(
    missing_steps_message(review),
    content="No required runbook steps remain",
  )
  inspect(requires_commander(1, review), content="false")
}

///|
test "runbook remaining steps and severity labels are deterministic" {
  let runbook = runbook_for_severity(3)
  let engine = test_builder().build("Detected", incident("T-7", "api", 3))
  ignore(engine.try_send("Acknowledge"))
  inspect(required_runbook_owners(runbook).length(), content="4")
  inspect(runbook_event_index(runbook, "Mitigate") is Some(4), content="true")
  inspect(remaining_required_steps(runbook, engine.history()), content="5")
  inspect(severity_label(3), content="SEV-1")
  inspect(severity_label(2), content="SEV-2")
  inspect(severity_label(1), content="SEV-3")
}
