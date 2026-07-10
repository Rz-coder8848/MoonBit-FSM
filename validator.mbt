///|
fn[S : Hash + Eq] push_unique(
  items : Array[S],
  seen : Map[S, Bool],
  value : S,
) -> Unit {
  if !seen.contains(value) {
    seen.set(value, true)
    items.push(value)
  }
}

///|
fn[S : Hash + Eq, E, Ctx] collect_states(
  builder : Builder[S, E, Ctx],
) -> Array[S] {
  let states = []
  let seen = {}
  for t in builder.config.transitions {
    push_unique(states, seen, t.from)
    push_unique(states, seen, t.to)
  }
  states
}

///|
fn[S : Hash + Eq, E, Ctx] reachable_states(
  builder : Builder[S, E, Ctx],
  initial_state : S,
) -> Array[S] {
  let reachable = {}
  let ordered = []
  let queue = [initial_state]
  let mut head = 0

  reachable.set(initial_state, true)
  ordered.push(initial_state)

  while head < queue.length() {
    let current = queue[head]
    head = head + 1

    for t in builder.config.transitions {
      if t.from == current && !reachable.contains(t.to) {
        reachable.set(t.to, true)
        ordered.push(t.to)
        queue.push(t.to)
      }
    }
  }

  ordered
}

///|
fn[S : Eq, E, Ctx] state_has_outgoing(
  builder : Builder[S, E, Ctx],
  state : S,
) -> Bool {
  for t in builder.config.transitions {
    if t.from == state {
      return true
    }
  }
  false
}

///|
fn[S : Hash + Eq, E, Ctx] find_unreachable_states(
  builder : Builder[S, E, Ctx],
  initial_state : S,
) -> Array[S] {
  let reachable = reachable_states(builder, initial_state)
  let reachable_seen = {}
  for state in reachable {
    reachable_seen.set(state, true)
  }

  let missing_states = []
  let missing_seen = {}
  for state in collect_states(builder) {
    if !reachable_seen.contains(state) {
      push_unique(missing_states, missing_seen, state)
    }
  }
  missing_states
}

///|
fn[S : Hash + Eq, E, Ctx] find_dead_end_states(
  builder : Builder[S, E, Ctx],
  initial_state : S,
) -> Array[S] {
  let dead_ends = []
  let seen = {}
  for state in reachable_states(builder, initial_state) {
    if !state_has_outgoing(builder, state) {
      push_unique(dead_ends, seen, state)
    }
  }
  dead_ends
}

///|
fn[S : Hash + Eq, E, Ctx] find_states_without_outgoing_edges(
  builder : Builder[S, E, Ctx],
) -> Array[S] {
  let states_without_edges = []
  let seen = {}
  for state in collect_states(builder) {
    if !state_has_outgoing(builder, state) {
      push_unique(states_without_edges, seen, state)
    }
  }
  states_without_edges
}

///|
fn[S : Eq, E : Eq] duplicate_exists(
  items : Array[DuplicateTransition[S, E]],
  candidate : DuplicateTransition[S, E],
) -> Bool {
  for item in items {
    if item == candidate {
      return true
    }
  }
  false
}

///|
/// Returns duplicate `(state, event)` definitions discovered in a builder.
pub fn[S : Eq, E : Eq, Ctx] duplicate_transition_entries(
  builder : Builder[S, E, Ctx],
) -> Array[DuplicateTransition[S, E]] {
  let seen_pairs = []
  let duplicates = []

  for t in builder.config.transitions {
    let candidate : DuplicateTransition[S, E] = { from: t.from, event: t.event }
    let mut already_seen = false
    for pair in seen_pairs {
      if pair == candidate {
        already_seen = true
        break
      }
    }

    if already_seen {
      if !duplicate_exists(duplicates, candidate) {
        duplicates.push(candidate)
      }
    } else {
      seen_pairs.push(candidate)
    }
  }

  duplicates
}

///|
/// Validates the FSM configuration for unreachable states, dead ends, and duplicates.
pub fn[S : Hash + Eq, E : Eq, Ctx] validate_report(
  builder : Builder[S, E, Ctx],
  initial_state : S,
) -> ValidationReport[S, E] {
  {
    unreachable_states: find_unreachable_states(builder, initial_state),
    dead_end_states: find_dead_end_states(builder, initial_state),
    duplicate_transitions: duplicate_transition_entries(builder),
    states_without_outgoing_edges: find_states_without_outgoing_edges(builder),
  }
}

///|
/// Returns the list of unreachable states for backwards compatibility.
pub fn[S : Hash + Eq, E : Eq, Ctx] validate(
  builder : Builder[S, E, Ctx],
  initial_state : S,
) -> Array[S] {
  validate_report(builder, initial_state).unreachable_states
}
