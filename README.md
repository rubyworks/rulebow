# Ergo 押忍

[Homepage](http://rubyworks.github.com/ergo) /
[Report Issue](http://github.com/rubyworks/ergo/issues) /
[Source Code](http://github.com/rubyworks/ergo) /
[IRC Channel](http://chat.us.freenode.net/rubyworks)

***"Logic programming meets the build tool."***

Ergo is a build tool that promotes continuous integration via logic
programming. With Ergo, the Ruby developer defines rules and state
conditions. The rules are applied when their state conditions are
met. Through repetitive application, this allows a project to all
but manage itself.

## Instructions

Below you will find a breif quick start guide just to give you 
some familiarity with Ergo, and how to get up and running in a
hot minute. For more detailed instructions and explination of
terms and how things work under-the-hood, please have a look
at the following resources.

* [Overview of Ergo](http://wiki.github.com/rubyworks/ergo)
* [Ergo Recepies](http://wiki.github.com/rubyworks/ergo)
* [API Documentation](http://rubydoc.info/gems/ergo/frames)


## Getting Started in a Hot Minute

### Installation

Directly via Rubygems:

    $ gem install ergo

Or by adding `gem "ergo"` to your Gemfile and running:

    $ bundle install

### Setup

Create a `.ergo` directory in your project.

    $ mkdir .ergo

Edit the `.ergo/rules.rb` file.

    $ vi .ergo/rules.rb

And add the following example rules to the file.

    manifest = %w[bin/**/* lib/**/* *.md]

    state :need_manifest? do
      files = manifest.map{ |d| Dir[d] }.flatten
      saved = File.readlines('MANIFEST').map{ |f| f.strip }
      files != saved
    end

    desc "update manifest"
    rule need_manifest? do
      files = manifest.map{ |d| Dir[d] }.flatten
      File.open('MANIFEST', 'w'){ |f| f << files.join("\n") }
    end

    desc "run my minitests"
    rule 'lib/**/*.rb' do
      $: << 'lib'
      files = Dir.glob('test/**/*_test.rb') 
      files.each{|file| require "./" + file}
    end

Of course we made some basic assumption about your project so you will want
to modify these to suite you needs (or dispose of them and right some fresh).
Nonetheless this script provides some clear example of the basic of writing 
Ergo rule scripts.

In the example we first create a *state* called `update_manifest?`. It's
code simple checks to see if the list of files in our project's MANIFEST
file matches the project files we expect to be there. Notice it returns
a boolean value, true or false. To go with this state we create a rule
that uses the state by calling an `update_manifest?` method. This method
was created by the state definition. The *rule procedure* updates the 
MANIFEST file whenever the state return `true`, i.e. the manifest does
not have the expected content.

At the end of our example script we create an additional rule. This
one does not reference a defined state. Instead it create a *file state*
implicitly by passing a string argument to `rule`. A file state has a
very simple and bery useful definition. It returns `true` when ever a
mathcing file has changed from one execution of the script to the next.
In other words, per this example, whenever a Ruby file in the `lib` 
directory changes, Ergo is going to run the units tests in the `test` 
directory.

Okay, so now we have a example rules script and have a basic grasp of
how it works, we can run it simple by invoking the `ergo` command on
command line.

    $ ergo

And away we go!!!



## Overview

### Rule Script

The Ergo *rules script* is looked up by the name `.ergo/rules.rb`.
Where the file is found is taken to be the *root* directory.
Ergo will change to this directory before applying the script's 
rules.

If you prefer to use a different script file, you could, of course soft
link `.ergo/rules.rb` to your perfered file. But you could instead add an
`import "filename"` in the file instead. Another option is to create a
`.option` file and add a `-S filename` entry under `ergo`. It can handle
a file glob, so for instance you could specify `task/*.ergo` and all matching
files will be used.

Rule scripts are just Ruby scripts using a special DSL (domain specific
language). They primarily contain a collection of `state` and `rule`
definitions. States define conditions and rules define procedures to
take based on those states.

### States

States are  conditions upon which rules depend to decide when a
rules procedure should applied. General states are defined using the
`state` method with a code block to express the condition. General
states are given a specific name.

```ruby
  state :happy_hour? do
    t = Time.now; t.hour >= 2 && t.hour <= 3
  end
```

These nemed states create a method, which is called when
defining rules (see below). But states can also be anonymous.
A most useful type of anonymous state is the `file` state. The 
file state defines a condition to check files for changes since
the previous "firing".

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
    # mast is a program to handles manifest

    state :update_manifest? do
      ! sh "mast --quiet --verify"
    end

    rule update_manifest? do
      sh "mast --update"
    end
```

To create a Rule for a file state, we can use the `file` state
method mentioned previously.

```ruby
    rule file('demo/*.md') do |files|
      system `qed #{files.join(' ')}`
    end
```

But file states are so command that using the `file` method isn't 
necessary when it is the only condition. Rules that are passed
a string or a regular expression for the state are automatically
interpreted to be a file state.

```ruby
    rule 'man/*.ronn' do |paths|
      system 'ronn ' + paths.join(' ')
    end
```

### Logic

Rules sometimes require more nuanced conditions based on multiple states. 
Ergo has a state logic system based on *set logic* that can be used
to build complex states using logical operators `&` (And) and `|` (Or).

```ruby
    rule happy_hour? & file('*.happy') do |files|
      puts "These are your happy files:"
      puts files.join("\n")
    end
```

### Books

Rules can be grouped together into books. Books make it possible to
only run a selection of rules rather than all of them.

```ruby
    book :test
    rule '{test,lib}/' do
      sh 'rubytest'
    end
```

Rule books are triggered via the command line by supplying the name
of the books to be run (see Application). All rules belong to the *master
rule book* --the set of rules that are run by default when on book
name is passed to the ergo command line tool. To make a rule *private*
to it's book, put `private` before the `book` method.

```ruby
    private book :test
    rule '{test,lib}/' do
      sh 'rubytest'
    end
```


### Descriptions

Rules can be given descriptions using the `desc` method. This simply allows
a developer to get a list of the available rules by using the `-R/--rules`
option with the ergo command. For example, if `rules.rb` contains:

```ruby
    desc "run unit tests"
    rule '{test,lib}/' do
      sh "rubytest"
    end
```

The we can see the rule listed:

```sh
    $ ergo -R
    # /home/joe/project/foo
    Rules:
    - run unit tests
```

### Application

To apply your rules simply use the `ergo` command.

```
    $ ergo
```

To run a specific book of rules, specify them on the command line.

```
    $ ergo test
```

Rules are always run in order of definition. So if one rule requires
that another be run before it, then it must be placed after that rule.
This makes the placement of rules a little less flexible than we might
like, but it keeps out a lot of extra cruft in the way of naming rules,
designating rule dependencies and resolving rule dependency graphs.

There are only a few options the command line tool takes. Use `-h/--help`
to get the full list. For file rules a very useful option is `-n` which
will cause the digest to considered "null and void" causing all files to
appear out-of-date, and thus causing all file rules to be triggered.


### Continuous Integration

Ergo can be run continuously by via the `-a/--autofire` option. To set the 
interval provide then number of seconds to wait between firings.

```
    $ ergo -a 60
```

This will run ergo every 60 seconds. By default the periodicity is 300
seconds, or every 5 minutes. To stop autofiring us `kill` on the pid
provided. (Note we will make an easier way to do this eventually.)


### Building Useful Rules

Ergo doesn't dictate how rule procedures are coded. It's just Ruby. While it
does provide easy access to FileUtils methods, beyond that the how of things
is completely up to the developer.

We do offer one recommendation that will likely make endeavors in this regard
much easier. Have a look at the [Detroit Toolchain](http://rubyworks.github.com/detroit).
It has numerous tools largely preconfigured and with built-in smarts to make
them quick and easy to put into action.


## Copyright & License

Ergo is copyrighted open-source software.

  Copyright (c) 2011 Rubyworks. All rights reserved.

It is modifiable and redistributable under the terms of the *BSD-2-Clause* license.

See the enclosed LICENSE.txt file for details.

(火)
