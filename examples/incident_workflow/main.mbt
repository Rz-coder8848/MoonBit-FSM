///|
/// Production incident context retained across an incident response run.
struct IncidentContext {
  incident_id : String
  service : String
  severity : Int
  responders : Int
  mitigations : Int
  elapsed_steps : Int
  customer_impact : Bool
  rollback_ready : Bool
}

///|
fn incident(id : String, service : String, severity : Int) -> IncidentContext {
  {
    incident_id: id,
    service,
    severity,
    responders: 0,
    mitigations: 0,
    elapsed_steps: 0,
    customer_impact: severity >= 2,
    rollback_ready: true,
  }
}

///|
fn with_tick(ctx : IncidentContext) -> IncidentContext {
  {
    incident_id: ctx.incident_id,
    service: ctx.service,
    severity: ctx.severity,
    responders: ctx.responders,
    mitigations: ctx.mitigations,
    elapsed_steps: ctx.elapsed_steps + 1,
    customer_impact: ctx.customer_impact,
    rollback_ready: ctx.rollback_ready,
  }
}

///|
fn acknowledged(ctx : IncidentContext) -> IncidentContext {
  let next = with_tick(ctx)
  {
    incident_id: next.incident_id,
    service: next.service,
    severity: next.severity,
    responders: next.responders + 1,
    mitigations: next.mitigations,
    elapsed_steps: next.elapsed_steps,
    customer_impact: next.customer_impact,
    rollback_ready: next.rollback_ready,
  }
}

///|
fn mitigated(ctx : IncidentContext) -> IncidentContext {
  let next = with_tick(ctx)
  {
    incident_id: next.incident_id,
    service: next.service,
    severity: next.severity,
    responders: next.responders,
    mitigations: next.mitigations + 1,
    elapsed_steps: next.elapsed_steps,
    customer_impact: next.customer_impact,
    rollback_ready: false,
  }
}

///|
fn monitoring(ctx : IncidentContext) -> IncidentContext {
  let next = with_tick(ctx)
  {
    incident_id: next.incident_id,
    service: next.service,
    severity: next.severity,
    responders: next.responders,
    mitigations: next.mitigations,
    elapsed_steps: next.elapsed_steps,
    customer_impact: false,
    rollback_ready: next.rollback_ready,
  }
}

///|
fn incident_builder() -> @fsm.Builder[String, String, IncidentContext] {
  @fsm.Builder::new()
  .transition_do("Detected", "Acknowledge", "Investigating", fn(_s, _e, ctx) {
    acknowledged(ctx)
  })
  .transition_if("Investigating", "Diagnose", "Mitigating", fn(_s, _e, ctx) {
    ctx.responders > 0
  })
  .transition_do("Mitigating", "Mitigate", "Monitoring", fn(_s, _e, ctx) {
    mitigated(ctx)
  })
  .transition_if_do(
    "Monitoring",
    "Verify",
    "Resolved",
    fn(_s, _e, ctx) { ctx.mitigations > 0 },
    fn(_s, _e, ctx) { monitoring(ctx) },
  )
  .transition("Investigating", "Escalate", "Escalated")
  .transition("Mitigating", "Escalate", "Escalated")
  .transition_if("Escalated", "AssignCommander", "Investigating", fn(
    _s,
    _e,
    ctx,
  ) {
    ctx.severity >= 2
  })
  .transition("Resolved", "Reopen", "Investigating")
  .transition("Resolved", "Postmortem", "Postmortem")
  .transition("Postmortem", "Publish", "Closed")
  .transition("Monitoring", "Rollback", "Investigating")
}

///|
fn print_incident(
  label : String,
  engine : @fsm.Engine[String, String, IncidentContext],
) -> Unit {
  let ctx = engine.context()
  println(
    "\{label}: \{ctx.incident_id} state=\{engine.state()} " +
    "responders=\{ctx.responders} mitigations=\{ctx.mitigations} " +
    "elapsed=\{ctx.elapsed_steps} impact=\{ctx.customer_impact}",
  )
}

///|
fn normal_response(
  builder : @fsm.Builder[String, String, IncidentContext],
) -> Unit {
  let engine = builder.build("Detected", incident("INC-2001", "payments", 2))
  let journal = @fsm.WorkflowJournal::new()
  ignore(engine.try_send_all(["Acknowledge", "Diagnose", "Mitigate", "Verify"]))
  ignore(journal.append_audit("INC-2001", engine.audit_log()))
  print_incident("Normal response", engine)
  println(
    "Journal entries=\{journal.entries().length()} incidents=\{journal.unacknowledged_incidents()}",
  )
}

///|
fn escalation_response(
  builder : @fsm.Builder[String, String, IncidentContext],
) -> Unit {
  let engine = builder.build("Detected", incident("INC-2002", "search", 3))
  let journal = @fsm.WorkflowJournal::new()
  let report = engine.try_send_with_budget(
    [
      "Acknowledge", "Escalate", "AssignCommander", "Diagnose", "Mitigate", "Verify",
    ],
    1,
  )
  ignore(journal.append_audit("INC-2002", engine.audit_log()))
  print_incident("Escalation response", engine)
  println(
    "Budget processed=\{report.processed} accepted=\{report.successful} " +
    "rejected=\{report.rejected} status=\{engine.state()}",
  )
  let sla = @fsm.evaluate_sla(
    { max_steps: 6, max_escalations: 1 },
    engine.context().elapsed_steps,
    1,
  )
  let status = @fsm.sla_status(sla)
  println("SLA=\{status}")
}

///|
fn rollback_response(
  builder : @fsm.Builder[String, String, IncidentContext],
) -> Unit {
  let engine = builder.build("Detected", incident("INC-2003", "catalog", 1))
  ignore(engine.try_send_all(["Acknowledge", "Diagnose", "Mitigate"]))
  let checkpoint = engine.checkpoint()
  let report = engine.try_send_all(["Verify", "Reopen", "Rollback"])
  if !report.complete {
    engine.restore(checkpoint)
  }
  print_incident("Rollback response", engine)
  println("Restored history=\{engine.history().length()}")
}

///|
fn main {
  println("--- Production Incident Response Example ---")
  let builder = incident_builder()
  normal_response(builder)
  escalation_response(builder)
  rollback_response(builder)
  let graph = @fsm.graph_summary(builder, "Detected")
  let risk = @fsm.workflow_risk_score(builder, "Detected")
  println(
    "Graph states=\{graph.state_count}, branches=\{graph.branching_states.length()}, " +
    "cycles=\{graph.has_cycle}, risk=\{risk}",
  )
  println("Mermaid Diagram:\n" + @fsm.to_mermaid(builder))
}
