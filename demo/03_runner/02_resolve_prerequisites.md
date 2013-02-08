# Resolving Prerequisites

The `Runner` class handles running rules. It takes `System` as an argument and
can run all applicable rules or trigger a named task.

## Task Prerequisites

### Handles Simple Prerequisite

Given a @system defined with a simple prerequisite:

    task :a => [:b] do
    end

    task :b do
    end

Then the Runner should resolve to this single prerequisite.

    runner = Fire::Runner.new(@system)

    a = @system.tasks[:a]

    prelist = runner.send(:resolve, a)
    prelist.assert == [:b]

### Handles DAG

Given a @system defined with a DAG:

    task :a => [:b, :c] do
    end

    task :b => [:c] do
    end

    task :c do
    end

Then the Runner should remove the redundancy from the list of
prerequisites to be run.

    runner = Fire::Runner.new(@system)

    a = @system.tasks[:a]

    prelist = runner.send(:resolve, a)
    prelist.assert == [:b, :c]

### Prevents Recursion

Given a @system defined with recursive prerequisites:

    task :a => [:b] do
    end

    task :b => [:a] do
    end

Then the Runner should resolve the requirements without the
infinite repetition.

    runner = Fire::Runner.new(@system)

    a = @system.tasks[:a]

    prelist = runner.send(:resolve, a)
    prelist.assert == [:b, :a]

Note: it would be better if this raised an error reporting the recursion,
but this has not been implemented yet.


## Rule Prerequisites

### Handles Simple Prerequisite

Given a @system defined with a simple prerequisite:

    rule true => [:b] do
    end

    task :b do
    end

Then the Runner should resolve to this single prerequisite.

    runner = Fire::Runner.new(@system)

    a = @system.rules.first  # only one there is

    prelist = runner.send(:resolve, a)
    prelist.assert == [:b]


