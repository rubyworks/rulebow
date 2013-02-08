# Fire (火)

[Homepage](http://rubyworks.github.com/fire) /
[Report Issue](http://github.com/rubyworks/fire/issues) /
[Source Code](http://github.com/rubyworks/fire) /
[IRC Channel](http://chat.us.freenode.net/rubyworks)


Fire is a rules-based build tool and continuous integration system.
The creative spark that created Fire is "logic programming meets build tool".
With it the Ruby developer defines project states and rules to follow
when those state are met. In this manner, a project can all but manage
itself!


## Instruction

### Rule Files

Rule files by default are looked up from a project's root directory
matching `task/file.rb` or `task/*.fire.rb`. All matching files will
be loaded. If you prefer to use a different location, you can create
a `.fire/script.rb` file and only that file will be used. In it you
can import any other paths you like.

Rule files are Ruby scripts, containing primarily a collection of
`state` and `rule` definitions. States define conditions and
rules define procedures to take based on such states.

### States

States are  conditions upon which rule depend to decide when a
rules procedure should run or not. States are defined using the
`state` method with a code block to express the condition. General
rules are given a specific name.

```ruby
  state :happy_hour? do
    t = Time.now; t.hour >= 2 && t.hour <= 3
  end
```

Named states define a method internally, which is called when
defining rules (see below). But states can also be anonymous.
A common type of anonymous state is the `file` state, which
automatically creates a condition to check for files on disk
that have changed since the previous "firing".

```ruby
    file('lib/**/*.rb')
```

Another such state is the `env` state, which is used to match
system environment variables. The variable's value can be matched
against a specific string or a regular expression.

```
    env('PATH'=>/foo/)
```

### Rules

Rules take a state as an argument and attaches it to an action
procedure. When fired, if the state condition evaluates as true,
the rule procedure will be called.

```ruby
    # Mast handles manifest updates.

    state :update_manifest? do
      ! system "mast --recent"
    end

    rule update_manifest? do
      system "mast -u"
    end
```

To create a Rule for a file state, we can use the `file` state
method mentioned previously.

```ruby
    rule file('demo/*.md') do |files|
      system `qed #{files.join(' ')}`
    end
```

But using `file` isn't necessary when it is the only condition b/c
rules that use a string or a regular expression for the state are
automatically interpreted to be a file state.

```ruby
    rule 'man/*.ronn' do |paths|
      system 'ronn ' + paths.join(' ')
    end
```

### State Logic

Rules sometimes require more nuanced conditions based on multiple states. 
Fire has a state logic system based on *set logic* that can be used
to build complex states using logical operators `&` (And) and `|` (Or).

```ruby
    rule happy_hour? & file('*.happy') do |files|
      puts "These are you happy files:"
      puts files.join("\n")
    end
```

### Named Rules

Rules can also be created that have no conditional state. Instead
these rules are given a name and the name acts as a *trigger*.
Triggered rules are distinguished from file rules by using a symbol
argument instead of a string.

```ruby
    rule :test do
      sh 'rubytest'
    end
```

These rules are then triggered via the command line, or as prerequisite
actions of other rules (see below). To make a trigger accessible via
the command line it must also be given a description, using the `desc`
method before the rule definition.

```ruby
    desc "run all unit tests"
    rule :test do
      sh "rubytest"
    end
```

### Prerequisites

Sometimes rules have prerequisite actions. And often different rules may
share the same prerequisite actions.

```ruby
    rule :setup do
      mkdir_p 'tmp'
    end

    desc "run all unit tests"
    preq :setup
    rule :test do
      mkdir_p 'tmp'
    end
```

### Running

To run your rules simply use the `fire` command.

```sh
    fire
```

There are few was to manually trigger builds. For file rules, 
the `-n` option will cause the digest to be "null and void",
which will cause all files to appear out-of-date and thus all
be triggered.

Triggers are specified as a command argument.

```sh
    fire test
```


### Continuous Integration

Fire can be run continuously by running autofire. To set the 
interval use the `-w/--wait` option.

```sh
    autofire -w 60
```

This run fire every 60 seconds. To stop autofiring run autofire
again.


### Building Useful Rules

Fire doesn't dictate how rule procedures are coded. It's just Ruby. While it
does provide easy access to FileUtils methods, beyond that the how of things
is completely up to the developer.

We do offer one recommendation that will likely make endeavors in this regard
much easier. Have a look at the [Detroit Toolchain](http://rubyworks.github.com/detroit).
It has numerous tools largely preconfigured and with built-in smarts to make
them quick and easy to put into action.


## Copyright & License

Fire is copyrighted open-source software.

  Copyright (c) 2011 Rubyworks. All rights reserved.

It is modifiable and redistributable under the terms of the *BSD-2-Clause* license.

See the enclosed LICENSE.txt file for details.

