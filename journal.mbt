///|
/// Severity used by an operational workflow journal.
pub(all) enum JournalLevel {
  Info
  Warning
  Error
  Critical
} derive(Eq)

///|
/// One immutable-facing entry in an operational audit stream.
pub(all) struct JournalEntry {
  sequence : Int
  ticket_id : String
  state : String
  event : String
  level : JournalLevel
  message : String
  mut acknowledged : Bool
}

///|
/// An in-memory journal suitable for deterministic tests and adapters.
pub(all) struct WorkflowJournal {
  mut entries : Array[JournalEntry]
  mut next_sequence : Int
}

///|
/// Creates an empty journal with sequence numbers starting at one.
pub fn WorkflowJournal::new() -> WorkflowJournal {
  { entries: [], next_sequence: 1 }
}

///|
fn WorkflowJournal::append_entry(
  self : WorkflowJournal,
  ticket_id : String,
  state : String,
  event : String,
  level : JournalLevel,
  message : String,
) -> Int {
  let sequence = self.next_sequence
  self.entries.push({
    sequence,
    ticket_id,
    state,
    event,
    level,
    message,
    acknowledged: false,
  })
  self.next_sequence += 1
  sequence
}

///|
/// Appends an informational operational note.
pub fn WorkflowJournal::info(
  self : WorkflowJournal,
  ticket_id : String,
  state : String,
  event : String,
  message : String,
) -> Int {
  self.append_entry(ticket_id, state, event, Info, message)
}

///|
/// Appends a warning that may need operator follow-up.
pub fn WorkflowJournal::warning(
  self : WorkflowJournal,
  ticket_id : String,
  state : String,
  event : String,
  message : String,
) -> Int {
  self.append_entry(ticket_id, state, event, Warning, message)
}

///|
/// Appends a recoverable error.
pub fn WorkflowJournal::error(
  self : WorkflowJournal,
  ticket_id : String,
  state : String,
  event : String,
  message : String,
) -> Int {
  self.append_entry(ticket_id, state, event, Error, message)
}

///|
/// Appends a critical incident requiring explicit acknowledgement.
pub fn WorkflowJournal::critical(
  self : WorkflowJournal,
  ticket_id : String,
  state : String,
  event : String,
  message : String,
) -> Int {
  self.append_entry(ticket_id, state, event, Critical, message)
}

///|
/// Reads a defensive copy of the journal.
pub fn WorkflowJournal::entries(self : WorkflowJournal) -> Array[JournalEntry] {
  self.entries.copy()
}

///|
/// Acknowledges one entry and reports whether it existed.
pub fn WorkflowJournal::acknowledge(
  self : WorkflowJournal,
  sequence : Int,
) -> Bool {
  for index in 0..<self.entries.length() {
    if self.entries[index].sequence == sequence {
      self.entries[index].acknowledged = true
      return true
    }
  }
  false
}

///|
/// Acknowledges every entry for a ticket, useful when an incident is closed.
pub fn WorkflowJournal::acknowledge_ticket(
  self : WorkflowJournal,
  ticket_id : String,
) -> Int {
  let mut acknowledged = 0
  for index in 0..<self.entries.length() {
    if self.entries[index].ticket_id == ticket_id &&
      !self.entries[index].acknowledged {
      self.entries[index].acknowledged = true
      acknowledged += 1
    }
  }
  acknowledged
}

///|
/// Counts entries at one severity.
pub fn WorkflowJournal::count_level(
  self : WorkflowJournal,
  level : JournalLevel,
) -> Int {
  let mut count = 0
  for entry in self.entries {
    if entry.level == level {
      count += 1
    }
  }
  count
}

///|
/// Counts unacknowledged error and critical entries.
pub fn WorkflowJournal::unacknowledged_incidents(self : WorkflowJournal) -> Int {
  let mut count = 0
  for entry in self.entries {
    if !entry.acknowledged && (entry.level == Error || entry.level == Critical) {
      count += 1
    }
  }
  count
}

///|
/// Returns entries belonging to a ticket in original sequence order.
pub fn WorkflowJournal::for_ticket(
  self : WorkflowJournal,
  ticket_id : String,
) -> Array[JournalEntry] {
  let result = []
  for entry in self.entries {
    if entry.ticket_id == ticket_id {
      result.push(entry)
    }
  }
  result
}

///|
/// Returns true when a ticket has a journal entry at a critical severity.
pub fn WorkflowJournal::has_critical(
  self : WorkflowJournal,
  ticket_id : String,
) -> Bool {
  for entry in self.entries {
    if entry.ticket_id == ticket_id && entry.level == Critical {
      return true
    }
  }
  false
}

///|
/// Adds all accepted and rejected events from a string-labelled FSM audit log.
pub fn WorkflowJournal::append_audit(
  self : WorkflowJournal,
  ticket_id : String,
  audit : Array[AuditRecord[String, String]],
) -> Int {
  let mut appended = 0
  for record in audit {
    let level = match record.error {
      None => Info
      Some(GuardRejected) => Warning
      Some(EventNotHandledInCurrentState) => Error
      Some(NoTransitionsForCurrentState) => Error
      Some(DuplicateTransitionDefinition) => Critical
      Some(InvalidConfiguration) => Critical
    }
    let message = match record.error {
      None => format_transition_log(record.from, record.event, record.to)
      Some(error) => format_transition_error(error)
    }
    ignore(
      self.append_entry(ticket_id, record.to, record.event, level, message),
    )
    appended += 1
  }
  appended
}

///|
/// Formats a compact line for console logs and line-oriented exporters.
pub fn journal_line(entry : JournalEntry) -> String {
  "#\{entry.sequence} [\{format_journal_level(entry.level)}] " +
  "\{entry.ticket_id} \{entry.state} \{entry.event}: \{entry.message}"
}

///|
pub fn format_journal_level(level : JournalLevel) -> String {
  match level {
    Info => "INFO"
    Warning => "WARN"
    Error => "ERROR"
    Critical => "CRITICAL"
  }
}

///|
/// A service-level target expressed in deterministic workflow steps.
pub(all) struct SlaTarget {
  max_steps : Int
  max_escalations : Int
} derive(Eq)

///|
/// Evaluation of a ticket against its service-level target.
pub(all) struct SlaEvaluation {
  within_steps : Bool
  within_escalations : Bool
  breached : Bool
  remaining_steps : Int
  remaining_escalations : Int
}

///|
/// Evaluates elapsed steps and escalation count without depending on a clock.
pub fn evaluate_sla(
  target : SlaTarget,
  elapsed_steps : Int,
  escalations : Int,
) -> SlaEvaluation {
  let remaining_steps = target.max_steps - elapsed_steps
  let remaining_escalations = target.max_escalations - escalations
  let within_steps = remaining_steps >= 0
  let within_escalations = remaining_escalations >= 0
  {
    within_steps,
    within_escalations,
    breached: !within_steps || !within_escalations,
    remaining_steps,
    remaining_escalations,
  }
}

///|
/// Returns a readable SLA status for dashboards.
pub fn sla_status(evaluation : SlaEvaluation) -> String {
  if evaluation.breached {
    "BREACHED"
  } else if evaluation.remaining_steps == 0 ||
    evaluation.remaining_escalations == 0 {
    "AT_LIMIT"
  } else {
    "WITHIN_TARGET"
  }
}

///|
/// A small aggregate for operational reporting across many tickets.
pub(all) struct JournalAggregate {
  tickets : Int
  entries : Int
  informational : Int
  warnings : Int
  errors : Int
  critical : Int
  unacknowledged : Int
}

///|
/// Aggregates a collection of ticket journals into one report.
pub fn aggregate_journals(
  journals : Array[WorkflowJournal],
) -> JournalAggregate {
  let ticket_ids = Map([])
  let mut entries = 0
  let mut informational = 0
  let mut warnings = 0
  let mut errors = 0
  let mut critical = 0
  let mut unacknowledged = 0
  for journal in journals {
    for entry in journal.entries {
      ticket_ids.set(entry.ticket_id, true)
      entries += 1
      if !entry.acknowledged {
        unacknowledged += 1
      }
      match entry.level {
        Info => informational += 1
        Warning => warnings += 1
        Error => errors += 1
        Critical => critical += 1
      }
    }
  }
  {
    tickets: ticket_ids.length(),
    entries,
    informational,
    warnings,
    errors,
    critical,
    unacknowledged,
  }
}
