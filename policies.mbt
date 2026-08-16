///|
/// Describes which deterministic failures may be retried by a caller.
pub(all) enum RetryMode {
  Never
  GuardOnly
  UnknownEventOnly
  Recoverable
} derive(Eq)

///|
/// A bounded retry policy for integrations that can change context between attempts.
pub(all) struct RetryPolicy {
  max_attempts : Int
  mode : RetryMode
} derive(Eq)

///|
/// Creates a retry policy. The initial attempt is always counted.
pub fn RetryPolicy::new(max_attempts : Int, mode : RetryMode) -> RetryPolicy {
  { max_attempts: if max_attempts < 1 { 1 } else { max_attempts }, mode }
}

///|
/// A single observable attempt made by a policy-driven dispatch.
pub(all) struct RetryAttempt[E] {
  attempt : Int
  event : E
  accepted : Bool
  error : TransitionError?
}

///|
/// Result of a bounded retry operation, including every failed attempt.
pub(all) struct RetryReport[E] {
  attempts : Array[RetryAttempt[E]]
  accepted : Bool
  exhausted : Bool
  final_error : TransitionError?
}

///|
fn retryable(mode : RetryMode, error : TransitionError) -> Bool {
  match mode {
    Never => false
    GuardOnly => error is GuardRejected
    UnknownEventOnly => error is EventNotHandledInCurrentState
    Recoverable =>
      error is GuardRejected || error is EventNotHandledInCurrentState
  }
}

///|
/// Sends one event repeatedly until it succeeds or the policy is exhausted.
///
/// The engine never sleeps or hides failures: callers can update external
/// context between calls, while the report remains deterministic and auditable.
pub fn[S : Hash + Eq, E : Hash + Eq, Ctx] Engine::try_send_with_retry(
  self : Engine[S, E, Ctx],
  event : E,
  policy : RetryPolicy,
) -> RetryReport[E] {
  let attempts = []
  let mut attempt = 1
  let mut accepted = false
  let mut exhausted = false
  let mut final_error : TransitionError? = None

  while attempt <= policy.max_attempts && !accepted {
    match self.try_send(event) {
      Ok(_) => {
        attempts.push({ attempt, event, accepted: true, error: None })
        accepted = true
      }
      Err(error) => {
        attempts.push({ attempt, event, accepted: false, error: Some(error) })
        final_error = Some(error)
        if !retryable(policy.mode, error) || attempt == policy.max_attempts {
          exhausted = true
        }
      }
    }
    attempt += 1
  }

  { attempts, accepted, exhausted, final_error }
}

///|
/// A budgeted event dispatch stops after too many rejected attempts.
pub(all) struct BudgetReport[E] {
  outcomes : Array[DispatchOutcome[E]]
  successful : Int
  rejected : Int
  processed : Int
  stopped : Bool
}

///|
/// Dispatches events in order while protecting a workflow from an error storm.
/// A zero budget means that the first rejection stops the batch.
pub fn[S : Hash + Eq, E : Hash + Eq, Ctx] Engine::try_send_with_budget(
  self : Engine[S, E, Ctx],
  events : Array[E],
  rejection_budget : Int,
) -> BudgetReport[E] {
  let outcomes = []
  let mut successful = 0
  let mut rejected = 0
  let mut processed = 0
  let mut stopped = false

  for event in events {
    if stopped {
      continue
    }
    match self.try_send(event) {
      Ok(_) => {
        successful += 1
        processed += 1
        outcomes.push({ event, success: true, error: None })
      }
      Err(error) => {
        rejected += 1
        processed += 1
        outcomes.push({ event, success: false, error: Some(error) })
        if rejected > rejection_budget {
          stopped = true
        }
      }
    }
  }

  { outcomes, successful, rejected, processed, stopped }
}

///|
/// Returns the number of successful transitions represented by a history.
pub fn[S, E] successful_transitions(
  history : Array[TransitionRecord[S, E]],
) -> Int {
  history.length()
}

///|
/// A compact operational summary suitable for dashboards and acceptance logs.
pub(all) struct HistorySummary {
  transitions : Int
  guarded_transitions : Int
  action_transitions : Int
  distinct_states : Int
  first_state : String?
  last_state : String?
}

///|
/// Summarizes a string-labelled workflow history without storing extra runtime state.
pub fn history_summary(
  history : Array[TransitionRecord[String, String]],
) -> HistorySummary {
  let seen = Map([])
  let mut guarded = 0
  let mut actions = 0
  for record in history {
    seen.set(record.from, true)
    seen.set(record.to, true)
    if record.used_guard {
      guarded += 1
    }
    if record.used_action {
      actions += 1
    }
  }
  let first = history.get(0)
  let last = history.get(history.length() - 1)
  {
    transitions: history.length(),
    guarded_transitions: guarded,
    action_transitions: actions,
    distinct_states: seen.length(),
    first_state: first_history_state(first),
    last_state: last_history_state(last),
  }
}

///|
fn first_history_state(record : TransitionRecord[String, String]?) -> String? {
  match record {
    Some(item) => Some(item.from)
    None => None
  }
}

///|
fn last_history_state(record : TransitionRecord[String, String]?) -> String? {
  match record {
    Some(item) => Some(item.to)
    None => None
  }
}
