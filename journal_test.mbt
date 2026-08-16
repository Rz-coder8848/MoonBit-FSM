///|
test "journal preserves sequence and severity counts" {
  let journal = WorkflowJournal::new()
  let first = journal.info("T-1", "Open", "Create", "ticket created")
  let second = journal.warning(
    "T-1", "Pending", "Wait", "customer response pending",
  )
  let third = journal.critical("T-2", "Error", "Fault", "device unavailable")
  inspect(first, content="1")
  inspect(second, content="2")
  inspect(third, content="3")
  inspect(journal.entries().length(), content="3")
  inspect(journal.count_level(Info), content="1")
  inspect(journal.count_level(Warning), content="1")
  inspect(journal.count_level(Critical), content="1")
  inspect(journal.unacknowledged_incidents(), content="1")
}

///|
test "journal acknowledgements are idempotent and ticket scoped" {
  let journal = WorkflowJournal::new()
  ignore(journal.error("T-1", "Open", "Fail", "first"))
  ignore(journal.critical("T-1", "Open", "Fail", "second"))
  ignore(journal.error("T-2", "Open", "Fail", "other"))
  inspect(journal.acknowledge(1), content="true")
  inspect(journal.acknowledge(1), content="true")
  inspect(journal.unacknowledged_incidents(), content="2")
  inspect(journal.acknowledge_ticket("T-1"), content="1")
  inspect(journal.unacknowledged_incidents(), content="1")
  inspect(journal.acknowledge(99), content="false")
}

///|
test "journal filters tickets and renders stable lines" {
  let journal = WorkflowJournal::new()
  ignore(journal.info("T-1", "Open", "Create", "created"))
  ignore(journal.warning("T-2", "Open", "Wait", "waiting"))
  ignore(journal.error("T-1", "Review", "Reject", "rejected"))
  let ticket = journal.for_ticket("T-1")
  inspect(ticket.length(), content="2")
  inspect(journal.has_critical("T-1"), content="false")
  inspect(
    journal_line(ticket[1]),
    content="#3 [ERROR] T-1 Review Reject: rejected",
  )
  inspect(format_journal_level(Critical), content="CRITICAL")
}

///|
test "audit records map to operational journal entries" {
  let builder : Builder[String, String, Unit] = Builder::new().transition(
    "Open", "Close", "Closed",
  )
  let engine = builder.build("Open", ())
  ignore(engine.try_send("Close"))
  ignore(engine.try_send("Retry"))
  let journal = WorkflowJournal::new()
  inspect(journal.append_audit("T-9", engine.audit_log()), content="2")
  inspect(journal.count_level(Info), content="1")
  inspect(journal.count_level(Error), content="1")
  inspect(
    journal.entries()[0].message,
    content="Transition: Open --(Close)--> Closed",
  )
}

///|
test "sla evaluation distinguishes target, limit, and breach" {
  let target : SlaTarget = { max_steps: 5, max_escalations: 1 }
  let within = evaluate_sla(target, 2, 0)
  let limit = evaluate_sla(target, 5, 1)
  let breach = evaluate_sla(target, 6, 0)
  inspect(within.breached, content="false")
  inspect(sla_status(within), content="WITHIN_TARGET")
  inspect(sla_status(limit), content="AT_LIMIT")
  inspect(breach.breached, content="true")
  inspect(breach.remaining_steps, content="-1")
}

///|
test "journal aggregation combines multiple ticket streams" {
  let first = WorkflowJournal::new()
  ignore(first.info("T-1", "Open", "Create", "created"))
  ignore(first.error("T-1", "Open", "Fail", "failed"))
  let second = WorkflowJournal::new()
  ignore(second.warning("T-2", "Open", "Wait", "waiting"))
  let aggregate = aggregate_journals([first, second])
  inspect(aggregate.tickets, content="2")
  inspect(aggregate.entries, content="3")
  inspect(aggregate.informational, content="1")
  inspect(aggregate.warnings, content="1")
  inspect(aggregate.errors, content="1")
  inspect(aggregate.unacknowledged, content="3")
}
