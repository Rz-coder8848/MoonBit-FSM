///|
/// A composable filter for operational journal queries.
pub(all) struct JournalFilter {
  ticket_id : String?
  minimum_level : JournalLevel?
  include_acknowledged : Bool
  event_prefix : String?
}

///|
/// Creates a filter that returns every unacknowledged incident.
pub fn JournalFilter::open_incidents() -> JournalFilter {
  {
    ticket_id: None,
    minimum_level: Some(Error),
    include_acknowledged: false,
    event_prefix: None,
  }
}

///|
/// Creates a filter for one ticket and one event family.
pub fn JournalFilter::ticket_events(
  ticket_id : String,
  event_prefix : String,
) -> JournalFilter {
  {
    ticket_id: Some(ticket_id),
    minimum_level: None,
    include_acknowledged: true,
    event_prefix: Some(event_prefix),
  }
}

///|
fn level_rank(level : JournalLevel) -> Int {
  match level {
    Info => 0
    Warning => 1
    Error => 2
    Critical => 3
  }
}

///|
fn starts_with(value : String, prefix : String) -> Bool {
  let value_chars = value.to_array()
  let prefix_chars = prefix.to_array()
  if prefix_chars.length() > value_chars.length() {
    return false
  }
  for index in 0..<prefix_chars.length() {
    if value_chars[index] != prefix_chars[index] {
      return false
    }
  }
  true
}

///|
fn matches_filter(entry : JournalEntry, filter : JournalFilter) -> Bool {
  let ticket_matches = match filter.ticket_id {
    None => true
    Some(ticket) => entry.ticket_id == ticket
  }
  let level_matches = match filter.minimum_level {
    None => true
    Some(level) => level_rank(entry.level) >= level_rank(level)
  }
  let acknowledgement_matches = filter.include_acknowledged ||
    !entry.acknowledged
  let event_matches = match filter.event_prefix {
    None => true
    Some(prefix) => starts_with(entry.event, prefix)
  }
  ticket_matches && level_matches && acknowledgement_matches && event_matches
}

///|
/// Executes a filter against a journal without changing the journal.
pub fn query_journal(
  journal : WorkflowJournal,
  filter : JournalFilter,
) -> Array[JournalEntry] {
  let result = []
  for entry in journal.entries {
    if matches_filter(entry, filter) {
      result.push(entry)
    }
  }
  result
}

///|
/// Returns the latest matching entry, if one exists.
pub fn latest_matching(
  journal : WorkflowJournal,
  filter : JournalFilter,
) -> JournalEntry? {
  let matches = query_journal(journal, filter)
  matches.get(matches.length() - 1)
}

///|
/// A ticket-level operational summary for dashboards.
pub(all) struct TicketJournalSummary {
  ticket_id : String
  total_entries : Int
  accepted_events : Int
  warnings : Int
  incidents : Int
  critical : Int
  unacknowledged : Int
  last_state : String?
}

///|
/// Summarizes one ticket using the journal's stable sequence order.
pub fn summarize_ticket(
  journal : WorkflowJournal,
  ticket_id : String,
) -> TicketJournalSummary {
  let entries = journal.for_ticket(ticket_id)
  let mut accepted = 0
  let mut warnings = 0
  let mut incidents = 0
  let mut critical = 0
  let mut unacknowledged = 0
  for entry in entries {
    if entry.level == Info {
      accepted += 1
    }
    if entry.level == Warning {
      warnings += 1
    }
    if entry.level == Error {
      incidents += 1
    }
    if entry.level == Critical {
      critical += 1
    }
    if !entry.acknowledged && entry.level != Info {
      unacknowledged += 1
    }
  }
  let last_state = match journal.latest_for_ticket(ticket_id) {
    Some(entry) => Some(entry.state)
    None => None
  }
  {
    ticket_id,
    total_entries: entries.length(),
    accepted_events: accepted,
    warnings,
    incidents,
    critical,
    unacknowledged,
    last_state,
  }
}

///|
/// Finds the final journal entry belonging to a ticket.
pub fn WorkflowJournal::latest_for_ticket(
  self : WorkflowJournal,
  ticket_id : String,
) -> JournalEntry? {
  let mut latest : JournalEntry? = None
  for entry in self.entries {
    if entry.ticket_id == ticket_id {
      latest = Some(entry)
    }
  }
  latest
}

///|
/// Returns whether a journal has any unacknowledged entry at or above a level.
pub fn has_open_at_least(
  journal : WorkflowJournal,
  minimum : JournalLevel,
) -> Bool {
  for entry in journal.entries {
    if !entry.acknowledged && level_rank(entry.level) >= level_rank(minimum) {
      return true
    }
  }
  false
}

///|
/// Produces a count table in Info, Warning, Error, Critical order.
pub fn level_counts(journal : WorkflowJournal) -> Array[Int] {
  [
    journal.count_level(Info),
    journal.count_level(Warning),
    journal.count_level(Error),
    journal.count_level(Critical),
  ]
}
