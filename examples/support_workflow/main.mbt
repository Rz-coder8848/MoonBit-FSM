///|
/// A small but realistic customer-support workflow.
///
/// The example models the operational states found in a help-desk system:
/// triage, assignment, customer waiting, escalation, resolution, reopening,
/// and cancellation. Context actions retain the facts an operator needs for
/// audit and service-level reporting.
struct TicketContext {
  ticket_id : String
  priority : Int
  updates : Int
  escalations : Int
  customer_replies : Int
  elapsed_steps : Int
  customer_notified : Bool
}

///|
fn initial_ticket(id : String, priority : Int) -> TicketContext {
  {
    ticket_id: id,
    priority,
    updates: 0,
    escalations: 0,
    customer_replies: 0,
    elapsed_steps: 0,
    customer_notified: false,
  }
}

///|
fn tick(ctx : TicketContext) -> TicketContext {
  {
    ticket_id: ctx.ticket_id,
    priority: ctx.priority,
    updates: ctx.updates,
    escalations: ctx.escalations,
    customer_replies: ctx.customer_replies,
    elapsed_steps: ctx.elapsed_steps + 1,
    customer_notified: ctx.customer_notified,
  }
}

///|
fn mark_update(ctx : TicketContext) -> TicketContext {
  let next = tick(ctx)
  {
    ticket_id: next.ticket_id,
    priority: next.priority,
    updates: next.updates + 1,
    escalations: next.escalations,
    customer_replies: next.customer_replies,
    elapsed_steps: next.elapsed_steps,
    customer_notified: true,
  }
}

///|
fn mark_reply(ctx : TicketContext) -> TicketContext {
  let next = tick(ctx)
  {
    ticket_id: next.ticket_id,
    priority: next.priority,
    updates: next.updates,
    escalations: next.escalations,
    customer_replies: next.customer_replies + 1,
    elapsed_steps: next.elapsed_steps,
    customer_notified: next.customer_notified,
  }
}

///|
fn mark_escalation(ctx : TicketContext) -> TicketContext {
  let next = mark_update(ctx)
  {
    ticket_id: next.ticket_id,
    priority: next.priority,
    updates: next.updates,
    escalations: next.escalations + 1,
    customer_replies: next.customer_replies,
    elapsed_steps: next.elapsed_steps,
    customer_notified: next.customer_notified,
  }
}

///|
fn support_builder() -> @fsm.Builder[String, String, TicketContext] {
  @fsm.Builder::new()
  .transition_do("Open", "Triage", "Triaged", fn(_s, _e, ctx) {
    mark_update(ctx)
  })
  .transition_if("Triaged", "Assign", "InProgress", fn(_s, _e, ctx) {
    ctx.priority > 0
  })
  .transition_do("InProgress", "RequestInfo", "WaitingCustomer", fn(
    _s,
    _e,
    ctx,
  ) {
    mark_update(ctx)
  })
  .transition_do("WaitingCustomer", "CustomerReply", "InProgress", fn(
    _s,
    _e,
    ctx,
  ) {
    mark_reply(ctx)
  })
  .transition_if("InProgress", "Resolve", "Resolved", fn(_s, _e, ctx) {
    ctx.updates > 0 && ctx.customer_replies >= 0
  })
  .transition_do("InProgress", "Escalate", "Escalated", fn(_s, _e, ctx) {
    mark_escalation(ctx)
  })
  .transition_if("Escalated", "Resolve", "Resolved", fn(_s, _e, ctx) {
    ctx.escalations > 0
  })
  .transition("Resolved", "Close", "Closed")
  .transition_do("Resolved", "Reopen", "InProgress", fn(_s, _e, ctx) {
    tick(ctx)
  })
  .transition("Open", "Cancel", "Cancelled")
  .transition("Triaged", "Cancel", "Cancelled")
  .transition("InProgress", "Cancel", "Cancelled")
}

///|
fn print_context(label : String, context : TicketContext) -> Unit {
  println(
    "\{label}: ticket=\{context.ticket_id}, updates=\{context.updates}, " +
    "replies=\{context.customer_replies}, escalations=\{context.escalations}, " +
    "elapsed=\{context.elapsed_steps}, notified=\{context.customer_notified}",
  )
}

///|
fn run_normal_path(
  builder : @fsm.Builder[String, String, TicketContext],
) -> Unit {
  let engine = builder.build("Open", initial_ticket("SUP-1001", 2))
  let report = engine.try_send_all([
    "Triage", "Assign", "RequestInfo", "CustomerReply", "Resolve", "Close",
  ])
  println(
    "Normal ticket: state=\{engine.state()}, accepted=\{report.successful}, " +
    "rejected=\{report.rejected}",
  )
  print_context("Normal context", engine.context())
  let summary = @fsm.history_summary(engine.history())
  println(
    "Normal audit: transitions=\{summary.transitions}, " +
    "guarded=\{summary.guarded_transitions}, actions=\{summary.action_transitions}",
  )
}

///|
fn run_escalation_path(
  builder : @fsm.Builder[String, String, TicketContext],
) -> Unit {
  let engine = builder.build("Open", initial_ticket("SUP-1002", 3))
  let report = engine.try_send_all([
    "Triage", "Assign", "Escalate", "Resolve", "Reopen", "RequestInfo", "CustomerReply",
    "Resolve", "Close",
  ])
  println(
    "Escalation path: state=\{engine.state()}, accepted=\{report.successful}, " +
    "rejected=\{report.rejected}",
  )
  print_context("Escalation context", engine.context())
  let graph = @fsm.graph_summary(builder, "Open")
  println(
    "Graph review: states=\{graph.state_count}, transitions=\{graph.transition_count}, " +
    "branches=\{graph.branching_states.length()}, cycle=\{graph.has_cycle}",
  )
}

///|
fn run_budget_path(
  builder : @fsm.Builder[String, String, TicketContext],
) -> Unit {
  let engine = builder.build("Open", initial_ticket("SUP-1003", 1))
  let report = engine.try_send_with_budget(
    ["Resolve", "Assign", "Triage", "Assign", "Resolve"],
    1,
  )
  println(
    "Budget path: processed=\{report.processed}, accepted=\{report.successful}, " +
    "rejected=\{report.rejected}, stopped=\{report.stopped}",
  )
  print_context("Budget context", engine.context())
}

///|
fn main {
  println("--- Support Ticket Workflow Example ---")
  let builder = support_builder()
  run_normal_path(builder)
  run_escalation_path(builder)
  run_budget_path(builder)
  let score = @fsm.workflow_risk_score(builder, "Open")
  println("Risk score: \{score}")
  println("Mermaid Diagram:\n" + @fsm.to_mermaid(builder))
}
