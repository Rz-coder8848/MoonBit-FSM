///|
/// A deterministic runbook step used to guide operators through a response.
pub(all) struct RunbookStep {
  name : String
  event : String
  owner : String
  required : Bool
}

///|
/// A response runbook selected by incident severity.
pub(all) struct IncidentRunbook {
  title : String
  steps : Array[RunbookStep]
}

///|
fn required_step(name : String, event : String, owner : String) -> RunbookStep {
  { name, event, owner, required: true }
}

///|
fn optional_step(name : String, event : String, owner : String) -> RunbookStep {
  { name, event, owner, required: false }
}

///|
/// Returns the standard response runbook for a severity level.
pub fn runbook_for_severity(severity : Int) -> IncidentRunbook {
  if severity >= 3 {
    {
      title: "SEV-1 critical response",
      steps: [
        required_step("Acknowledge alert", "Acknowledge", "on-call"),
        required_step("Escalate commander", "Escalate", "incident-commander"),
        required_step(
          "Assign commander", "AssignCommander", "incident-commander",
        ),
        required_step("Diagnose impact", "Diagnose", "service-owner"),
        required_step("Mitigate customer impact", "Mitigate", "service-owner"),
        required_step("Verify recovery", "Verify", "observability"),
        optional_step("Publish postmortem", "Postmortem", "service-owner"),
      ],
    }
  } else if severity == 2 {
    {
      title: "SEV-2 customer-impacting response",
      steps: [
        required_step("Acknowledge alert", "Acknowledge", "on-call"),
        required_step("Diagnose impact", "Diagnose", "service-owner"),
        required_step("Mitigate customer impact", "Mitigate", "service-owner"),
        required_step("Verify recovery", "Verify", "observability"),
        optional_step("Publish postmortem", "Postmortem", "service-owner"),
      ],
    }
  } else {
    {
      title: "SEV-3 standard response",
      steps: [
        required_step("Acknowledge alert", "Acknowledge", "on-call"),
        required_step("Diagnose impact", "Diagnose", "service-owner"),
        required_step("Mitigate customer impact", "Mitigate", "service-owner"),
        optional_step("Verify recovery", "Verify", "observability"),
      ],
    }
  }
}

///|
/// Finds the first runbook step not represented by successful history.
pub fn next_runbook_step(
  runbook : IncidentRunbook,
  history : Array[@fsm.TransitionRecord[String, String]],
) -> RunbookStep? {
  for step in runbook.steps {
    let mut completed = false
    for record in history {
      if record.event == step.event {
        completed = true
      }
    }
    if !completed {
      return Some(step)
    }
  }
  None
}

///|
/// Counts completed required runbook steps.
pub fn completed_required_steps(
  runbook : IncidentRunbook,
  history : Array[@fsm.TransitionRecord[String, String]],
) -> Int {
  let mut completed = 0
  for step in runbook.steps {
    if !step.required {
      continue
    }
    for record in history {
      if record.event == step.event {
        completed += 1
        break
      }
    }
  }
  completed
}

///|
/// Returns a human-readable progress string for operator consoles.
pub fn runbook_progress(
  runbook : IncidentRunbook,
  history : Array[@fsm.TransitionRecord[String, String]],
) -> String {
  let completed = completed_required_steps(runbook, history)
  let mut total = 0
  for step in runbook.steps {
    if step.required {
      total += 1
    }
  }
  "\{runbook.title}: \{completed}/\{total} required steps"
}
