///|
struct OrderContext {
  amount : Int
  packages : Int
  refunds : Int
}

///|
fn order_builder() -> @fsm.Builder[String, String, OrderContext] {
  @fsm.Builder::new()
  .transition_do("Created", "Pay", "Paid", fn(
    _s : String,
    _e : String,
    ctx : OrderContext,
  ) {
    { amount: ctx.amount, packages: ctx.packages, refunds: ctx.refunds }
  })
  .transition_do("Paid", "Pack", "Packed", fn(
    _s : String,
    _e : String,
    ctx : OrderContext,
  ) {
    { amount: ctx.amount, packages: ctx.packages + 1, refunds: ctx.refunds }
  })
  .transition_if_do(
    "Packed",
    "Ship",
    "Shipped",
    fn(_s : String, _e : String, ctx : OrderContext) { ctx.packages > 0 },
    fn(_s : String, _e : String, ctx : OrderContext) {
      { amount: ctx.amount, packages: ctx.packages, refunds: ctx.refunds }
    },
  )
  .transition("Shipped", "Deliver", "Delivered")
  .transition("Paid", "Cancel", "Cancelled")
  .transition("Packed", "Cancel", "Cancelled")
  .transition_do("Shipped", "Return", "Returned", fn(
    _s : String,
    _e : String,
    ctx : OrderContext,
  ) {
    { amount: ctx.amount, packages: ctx.packages, refunds: ctx.refunds + 1 }
  })
  .on_exit("Paid", fn(_s : String, event : String, _ctx : OrderContext) {
    println("Leaving Paid after \{event}")
  })
  .on_enter("Delivered", fn(_s : String, _event : String, ctx : OrderContext) {
    println("Delivered amount=\{ctx.amount}")
  })
}

///|
fn print_report(label : String, report : @fsm.BatchReport[String]) -> Unit {
  println(
    "\{label}: successful=\{report.successful}, rejected=\{report.rejected}, complete=\{report.complete}",
  )
  for outcome in report.outcomes {
    match outcome.error {
      Some(err) =>
        println(
          "  \{outcome.event}: rejected (\{@fsm.format_transition_error(err)})",
        )
      None => println("  \{outcome.event}: accepted")
    }
  }
}

///|
fn main {
  println("--- Order Workflow Example ---")
  let builder = order_builder()

  let normal = builder.build("Created", { amount: 299, packages: 0, refunds: 0 })
  let normal_report = normal.try_send_all(["Pay", "Pack", "Ship", "Deliver"])
  print_report("Normal flow", normal_report)
  println("Final state: \{normal.state()}")
  println("History length: \{normal.history().length()}")
  println("Audit entries: \{normal.audit_log().length()}")
  println("Successful events: \{normal.metrics().successful}")

  let compensating = builder.build("Created", {
    amount: 299,
    packages: 0,
    refunds: 0,
  })
  ignore(compensating.try_send_all(["Pay", "Pack", "Ship"]))
  let checkpoint = compensating.checkpoint()
  let rollback_report = compensating.try_send_all(["Return", "Deliver"])
  print_report("Return batch", rollback_report)
  if !rollback_report.complete {
    compensating.restore(checkpoint)
  }
  println("Compensated state: \{compensating.state()}")
  println("Compensated refunds: \{compensating.context().refunds}")
  println("Compensated history: \{compensating.history().length()}")
  println("Mermaid Diagram:\n" + @fsm.to_mermaid(builder))
}
