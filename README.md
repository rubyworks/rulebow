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

states are  conditions defined using the `state` method
and a code block to express the condition. Usually they
are given a specific name.

```ruby
  state :happy_hour? do
    t = Time.now; t.hour >= 2 && t.hour <= 3
  end
```

States can however be annonymous. A common type of annonymous state
is the `file` state, which automatically builds a state condition
to check for files on disk that have changed since previous runs.

```ruby
    file('lib/**/*.rb')
```

Another useful state is the `env` state, which is used to match
system environment variables. The variable's value can be matched
against a specific string or a regular expression.

```
    env('PATH'=>/foo/)
```

### Rules

Rules take a state as an argument and attaches it to an action
procedure. When run, if the state condition evaluates as true,
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
    rule file('demo/') do
      sh `qed`
    end
```

But this isn't often necessary b/c rules that use a string or a 
regular expression for the state automatically create a file state.

```ruby
    rule 'man/*.ronn' do |paths|
      system 'ronn ' + paths.join(' ')
    end
```

### State Logic

Rule often require more nuanced conditions based on multiple states. 
Fire has a state logic system that can be used to build up complex
states using logic operators `&` and `|`.

```ruby
    rule happy_hour? & file('*.happy') do
      ...
    end
```

### Named Rules

Rules can also be created that have no conditional state. Instead
the rules are given a name and the name acts as a *trigger state*.

```ruby
    rule :test do
      sh 'rubytest'
    end
```

These rules are then triggered via the `fire` command line, or
as prerequiste actions, or other rules (see below). To make
a trigger accessiable via the command line the rule must also
be given a description, using the `desc` method before the
rule definition.

```ruby
    desc "run all unit tests"
    rule :test do
      sh "rubytest"
    end
```

### Prerequisites

Sometimes rules have prequisite actions. And often different
rules may share the same prequisite actions.

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


### Continious Integration

Fire can be run continously by running autofire. To set the 
interval use the `-w/--wait` option.

```sh
    autofire -w 60
```

This run fire every 60 seconds. To stop autofiring run autofire
again.


### Building Useful Rules

Fire doesn't dictate how rule procedures are coded. It's just Ruby.
While it does provide easy access to FileUtils methods, beyond that
the how of things is completely up to the developer.

We do offer one recommendation though, that will likely make endeavors
in the regard much easier. Have a look at the [Detroit Toolchain](http://rubyworks.github.com/detroit).
It has numerous tools largely preconfigured and with built-in smarts to
make them quick and easy to put into action.


## Copyright & License

Copyright (c) 2011 Rubyworks

Fire is distributable under the terms of the *BSD-2-Clause* license.

See LICENSE.txt for details.
