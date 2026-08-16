///|
/// Structural facts used to review a workflow before it is deployed.
pub(all) struct GraphSummary[S] {
  state_count : Int
  transition_count : Int
  terminal_states : Array[S]
  branching_states : Array[S]
  reachable_states : Array[S]
  unreachable_states : Array[S]
  has_cycle : Bool
  maximum_exploration_depth : Int
} derive(Eq)

///|
fn[S : Eq, E, Ctx] outgoing_count(
  builder : Builder[S, E, Ctx],
  state : S,
) -> Int {
  let mut count = 0
  for transition in builder.config.transitions {
    if transition.from == state {
      count += 1
    }
  }
  count
}

///|
fn[S : Hash + Eq, E, Ctx] reachable_from(
  builder : Builder[S, E, Ctx],
  start : S,
  target : S,
) -> Bool {
  let queue = [start]
  let seen = Map([])
  seen.set(start, true)
  let mut head = 0
  while head < queue.length() {
    let current = queue[head]
    head += 1
    if current == target && head > 1 {
      return true
    }
    for transition in builder.config.transitions {
      if transition.from == current && !seen.contains(transition.to) {
        seen.set(transition.to, true)
        queue.push(transition.to)
      }
    }
  }
  false
}

///|
fn[S : Hash + Eq, E, Ctx] has_cycle(builder : Builder[S, E, Ctx]) -> Bool {
  for transition in builder.config.transitions {
    if reachable_from(builder, transition.to, transition.from) {
      return true
    }
  }
  false
}

///|
fn[S : Hash + Eq, E, Ctx] exploration_depth(
  builder : Builder[S, E, Ctx],
  initial : S,
) -> Int {
  let queue : Array[(S, Int)] = [(initial, 0)]
  let seen = Map([])
  seen.set(initial, true)
  let mut head = 0
  let mut deepest = 0
  while head < queue.length() {
    let (current, depth) = queue[head]
    head += 1
    if depth > deepest {
      deepest = depth
    }
    for transition in builder.config.transitions {
      if transition.from == current && !seen.contains(transition.to) {
        seen.set(transition.to, true)
        queue.push((transition.to, depth + 1))
      }
    }
  }
  deepest
}

///|
/// Computes graph shape, reachability, branching, cycles, and terminal states.
pub fn[S : Hash + Eq, E, Ctx] graph_summary(
  builder : Builder[S, E, Ctx],
  initial_state : S,
) -> GraphSummary[S] {
  let all_states = collect_states(builder)
  let reachable = reachable_states(builder, initial_state)
  let disconnected = find_unreachable_states(builder, initial_state)
  let terminal = []
  let branching = []
  for state in all_states {
    let count = outgoing_count(builder, state)
    if count == 0 {
      terminal.push(state)
    }
    if count > 1 {
      branching.push(state)
    }
  }
  {
    state_count: all_states.length(),
    transition_count: builder.config.transitions.length(),
    terminal_states: terminal,
    branching_states: branching,
    reachable_states: reachable,
    unreachable_states: disconnected,
    has_cycle: has_cycle(builder),
    maximum_exploration_depth: exploration_depth(builder, initial_state),
  }
}

///|
/// Produces a stable integer risk score for dashboards and review gates.
/// The score rewards reachable structure and penalizes unreachable states,
/// duplicate definitions, and terminal states that are not explicitly expected.
pub fn[S : Hash + Eq, E : Eq, Ctx] workflow_risk_score(
  builder : Builder[S, E, Ctx],
  initial_state : S,
) -> Int {
  let report = validate_report(builder, initial_state)
  let summary = graph_summary(builder, initial_state)
  let mut score = summary.state_count + summary.transition_count
  score -= report.unreachable_states.length() * 3
  score -= report.duplicate_transitions.length() * 5
  score -= report.dead_end_states.length()
  if summary.has_cycle {
    score += 2
  }
  if score < 0 {
    0
  } else {
    score
  }
}

///|
/// Returns states with more than one outgoing event, useful for manual review.
pub fn[S : Hash + Eq, E, Ctx] branching_states(
  builder : Builder[S, E, Ctx],
) -> Array[S] {
  graph_summary(builder, collect_states(builder).get(0).unwrap()).branching_states
}
