///|
/// Review result produced before an incident response is handed over.
pub(all) struct RunbookReview {
  required_total : Int
  required_completed : Int
  missing_required : Array[String]
  next_owner : String?
  complete : Bool
  escalation_required : Bool
}

///|
/// Returns the event names in operator-facing runbook order.
pub fn runbook_events(runbook : IncidentRunbook) -> Array[String] {
  let events = []
  for step in runbook.steps {
    events.push(step.event)
  }
  events
}

///|
/// Returns unique owners in the order they first appear in the runbook.
pub fn runbook_owners(runbook : IncidentRunbook) -> Array[String] {
  let owners = []
  let seen = Map([])
  for step in runbook.steps {
    if !seen.contains(step.owner) {
      seen.set(step.owner, true)
      owners.push(step.owner)
    }
  }
  owners
}

///|
/// Checks whether an event is part of a runbook.
pub fn runbook_has_event(runbook : IncidentRunbook, event : String) -> Bool {
  for step in runbook.steps {
    if step.event == event {
      return true
    }
  }
  false
}

///|
/// Counts required runbook steps without inspecting execution history.
pub fn required_runbook_steps(runbook : IncidentRunbook) -> Int {
  let mut count = 0
  for step in runbook.steps {
    if step.required {
      count += 1
    }
  }
  count
}

///|
/// Builds a list of required events absent from a successful history.
pub fn missing_runbook_events(
  runbook : IncidentRunbook,
  history : Array[@fsm.TransitionRecord[String, String]],
) -> Array[String] {
  let missing = []
  for step in runbook.steps {
    if !step.required {
      continue
    }
    let mut found = false
    for record in history {
      if record.event == step.event {
        found = true
      }
    }
    if !found {
      missing.push(step.event)
    }
  }
  missing
}

///|
/// Returns the owner responsible for the first incomplete required step.
pub fn next_runbook_owner(
  runbook : IncidentRunbook,
  history : Array[@fsm.TransitionRecord[String, String]],
) -> String? {
  match next_runbook_step(runbook, history) {
    Some(step) => Some(step.owner)
    None => None
  }
}

///|
/// Reviews completion and escalation readiness for an incident handover.
pub fn review_runbook(
  runbook : IncidentRunbook,
  history : Array[@fsm.TransitionRecord[String, String]],
  severity : Int,
) -> RunbookReview {
  let total = required_runbook_steps(runbook)
  let completed = completed_required_steps(runbook, history)
  let missing = missing_runbook_events(runbook, history)
  {
    required_total: total,
    required_completed: completed,
    missing_required: missing,
    next_owner: next_runbook_owner(runbook, history),
    complete: missing.length() == 0,
    escalation_required: severity >= 3 && completed < total,
  }
}

///|
/// Computes an integer completion percentage for dashboards.
pub fn runbook_completion_percent(
  runbook : IncidentRunbook,
  history : Array[@fsm.TransitionRecord[String, String]],
) -> Int {
  let total = required_runbook_steps(runbook)
  if total == 0 {
    return 100
  }
  completed_required_steps(runbook, history) * 100 / total
}

///|
/// Returns a stable handover message with the next responsible owner.
pub fn handover_message(review : RunbookReview) -> String {
  if review.complete {
    "Runbook complete; response may enter closure review"
  } else {
    match review.next_owner {
      Some(owner) => "Pending required action owned by " + owner
      None => "Pending required action without an assigned owner"
    }
  }
}

///|
/// Lists every step owned by one operational role.
pub fn steps_for_owner(
  runbook : IncidentRunbook,
  owner : String,
) -> Array[RunbookStep] {
  let result = []
  for step in runbook.steps {
    if step.owner == owner {
      result.push(step)
    }
  }
  result
}

///|
/// Counts the required steps still assigned to one role.
pub fn pending_steps_for_owner(
  runbook : IncidentRunbook,
  history : Array[@fsm.TransitionRecord[String, String]],
  owner : String,
) -> Int {
  let mut pending = 0
  for step in steps_for_owner(runbook, owner) {
    if !step.required {
      continue
    }
    let mut completed = false
    for record in history {
      if record.event == step.event {
        completed = true
      }
    }
    if !completed {
      pending += 1
    }
  }
  pending
}

///|
/// A closure gate requires all mandatory steps and no unacknowledged incidents.
pub fn safe_to_close(
  review : RunbookReview,
  journal : @fsm.WorkflowJournal,
) -> Bool {
  review.complete && journal.unacknowledged_incidents() == 0
}

///|
/// Produces a compact review record for a handover document.
pub fn review_line(review : RunbookReview) -> String {
  let state = if review.complete { "COMPLETE" } else { "PENDING" }
  let escalation = if review.escalation_required {
    "ESCALATE"
  } else {
    "NORMAL"
  }
  "\{state} \{review.required_completed}/\{review.required_total} \{escalation}"
}

///|
/// Finds the first event assigned to a role, if the role is in the runbook.
pub fn first_event_for_owner(
  runbook : IncidentRunbook,
  owner : String,
) -> String? {
  for step in runbook.steps {
    if step.owner == owner {
      return Some(step.event)
    }
  }
  None
}

///|
/// Returns all required owners, preserving their runbook order.
pub fn required_runbook_owners(runbook : IncidentRunbook) -> Array[String] {
  let result = []
  let seen = Map([])
  for step in runbook.steps {
    if step.required && !seen.contains(step.owner) {
      seen.set(step.owner, true)
      result.push(step.owner)
    }
  }
  result
}

///|
/// Returns the zero-based position of an event in the runbook.
pub fn runbook_event_index(runbook : IncidentRunbook, event : String) -> Int? {
  for index in 0..<runbook.steps.length() {
    if runbook.steps[index].event == event {
      return Some(index)
    }
  }
  None
}

///|
/// Returns the number of required steps that remain after a history.
pub fn remaining_required_steps(
  runbook : IncidentRunbook,
  history : Array[@fsm.TransitionRecord[String, String]],
) -> Int {
  let review = review_runbook(runbook, history, 0)
  review.missing_required.length()
}

///|
/// Labels a severity for operator-facing handover records.
pub fn severity_label(severity : Int) -> String {
  if severity >= 3 {
    "SEV-1"
  } else if severity == 2 {
    "SEV-2"
  } else {
    "SEV-3"
  }
}

///|
/// Returns whether an operator still owns mandatory work.
pub fn owner_has_pending(
  runbook : IncidentRunbook,
  history : Array[@fsm.TransitionRecord[String, String]],
  owner : String,
) -> Bool {
  pending_steps_for_owner(runbook, history, owner) > 0
}

///|
/// Converts missing events into an operator-friendly handover sentence.
pub fn missing_steps_message(review : RunbookReview) -> String {
  if review.complete {
    "No required runbook steps remain"
  } else {
    "Missing required steps: " + review.missing_required.join(", ")
  }
}

///|
/// Applies the critical-response escalation rule used by the example.
pub fn requires_commander(severity : Int, review : RunbookReview) -> Bool {
  severity >= 3 && !review.complete
}
