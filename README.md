# Ergo 由

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

Below you will find a brief quick start guide just to give you 
some enough familiarity with Ergo get up and running in a
hot minute. For more detailed instruction and explination of
terms and how things work, please have a look at the following
resources.

* [Overview of Ergo](https://github.com/rubyworks/ergo/wiki/Overview-of-Ergo)
* [Ergo Recepies](https://github.com/rubyworks/ergo/wiki/Ergo-Recipes)
* [API Documentation](http://rubydoc.info/gems/ergo/frames)


## Let's Go!!!

### Installation

Directly via Rubygems:

```
  $ gem install ergo
```

Or by adding `gem "ergo"` to your Gemfile and running:

```
  $ bundle install
```

### Setup

Create a `.ergo` directory in your project.

```
  $ mkdir .ergo
```

Edit the `.ergo/rules.rb` file.

```
  $ vi .ergo/rules.rb
```

And add the following example rules to the file.

```ruby
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
```

Of course we made some basic assumption about your project so you will want
to modify these to suite you needs (or dispose of them and right some fresh).
Nonetheless this script provides some clear example of the basic of writing 
Ergo rule scripts.

In the example we first create a *state* called `update_manifest?`. It's
code simple checks to see if the list of files in our project's MANIFEST
file matches the project files we expect to be there. Notice it returns
a boolean value, true or false. To go with this state we create a *rule*
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


## Copyright & License

Ergo is copyrighted open-source software.

  Copyright (c) 2011 Rubyworks. All rights reserved.

It is modifiable and redistributable under the terms of the *BSD-2-Clause* license.

See the enclosed LICENSE.txt file for details.

(火)
