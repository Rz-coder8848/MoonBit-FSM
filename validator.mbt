///|
/// Validates the FSM configuration to detect isolated states via BFS.
/// Returns an array of isolated state identifiers.
pub fn[S : Hash + Eq, E, Ctx] validate(
  builder : Builder[S, E, Ctx],
  initial_state : S,
) -> Array[S] {
  let reachable = {}
  let queue = [initial_state]
  let mut head = 0

  reachable.set(initial_state, true)

  while head < queue.length() {
    let current = queue[head]
    head = head + 1

    for t in builder.config.transitions {
      if t.from == current {
        if !reachable.contains(t.to) {
          reachable.set(t.to, true)
          queue.push(t.to)
        }
      }
    }
  }

  let isolated = []
  for t in builder.config.transitions {
    if !reachable.contains(t.from) {
      // simple linear search to avoid duplicates
      let mut found = false
      for u in isolated {
        if u == t.from {
          found = true
          break
        }
      }
      if !found {
        isolated.push(t.from)
      }
    }
    if !reachable.contains(t.to) {
      let mut found = false
      for u in isolated {
        if u == t.to {
          found = true
          break
        }
      }
      if !found {
        isolated.push(t.to)
      }
    }
  }

  isolated
}
