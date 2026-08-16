///|
fn query_fixture() -> WorkflowJournal {
  let journal = WorkflowJournal::new()
  ignore(journal.info("T-1", "Open", "Transition", "created"))
  ignore(journal.warning("T-1", "Waiting", "Timeout", "waiting"))
  ignore(journal.error("T-1", "Error", "Transition", "failed"))
  ignore(journal.critical("T-2", "Error", "Transition", "outage"))
  ignore(journal.info("T-2", "Closed", "Transition", "closed"))
  journal
}

///|
test "journal filters isolate open severity and ticket events" {
  let journal = query_fixture()
  let open = query_journal(journal, JournalFilter::open_incidents())
  inspect(open.length(), content="2")
  let ticket = query_journal(
    journal,
    JournalFilter::ticket_events("T-1", "Transition"),
  )
  inspect(ticket.length(), content="2")
  inspect(
    latest_matching(journal, JournalFilter::open_incidents()).unwrap().ticket_id,
    content="T-2",
  )
}

///|
test "ticket summary and level counts are stable" {
  let journal = query_fixture()
  let summary = summarize_ticket(journal, "T-1")
  inspect(summary.ticket_id, content="T-1")
  inspect(summary.total_entries, content="3")
  inspect(summary.accepted_events, content="1")
  inspect(summary.warnings, content="1")
  inspect(summary.incidents, content="1")
  inspect(summary.unacknowledged, content="2")
  inspect(summary.last_state is Some("Error"), content="true")
  let counts = level_counts(journal)
  inspect(counts[0], content="2")
  inspect(counts[1], content="1")
  inspect(counts[2], content="1")
  inspect(counts[3], content="1")
}

///|
test "acknowledgement changes open severity queries" {
  let journal = query_fixture()
  inspect(has_open_at_least(journal, Critical), content="true")
  ignore(journal.acknowledge_ticket("T-2"))
  inspect(has_open_at_least(journal, Critical), content="false")
  inspect(has_open_at_least(journal, Warning), content="true")
}
