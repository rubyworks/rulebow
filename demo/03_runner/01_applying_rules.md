## Applying Rules

The `Runner` class handles running rules. It takes `System` as an argument and
can run all applicable rules or trigger a named task.

### True/False Rules

The simplist rule state is `true`, which means it will always run, or
`false` which means it will never run. These states are not very useful,
but they should still work.

Given a @system defined with a simple always-true rule, and another
always-false rule:

    rule true do
      assert true
    end

    rule false do
      assert false
    end

Then the Runner should run the true rule and not the false rule when
applying the system's rules.

    runner = Fire::Runner.new(@system)

    runner.run_rules

### Simple State Rule

Given a @system defined with a simple state:

    state :simple do
      true
    end

    rule simple do
      assert true
    end

    rule false do
      assert false
    end

Then the Runner should run the simple rule, but not the other.

    runner = Fire::Runner.new(@system)

    runner.run_rules
