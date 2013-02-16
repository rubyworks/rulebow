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

Ergo is not complicated. It goes not require a bazillion plugins.
Although some external tools can be helpful and used with it, and
it makes some procedures more convenient --for example it makes
FileUtils methods directly available in the build script context,
mostly it just trusts the devloper to know how to write the build
scripts they need.


## Instructions

Below you will find a brief "Hot Minute" guide for getting up and
running with Ergo quickly. It's just enough to give you familiarity
the basic ideas of Ergo and how to start putting it to good use.
For more detailed instruction, explination of terms and how the
dickens does it work under-the-hood, please consider any of the
following resources.

* [Overview of Ergo](https://github.com/rubyworks/ergo/wiki/Overview-of-Ergo)
* [Helpful FAQs](https://github.com/rubyworks/ergo/wiki/FAQ)
* [Ergo Recepies](https://github.com/rubyworks/ergo/wiki/Ergo-Recipes)
* [API Documentation](http://rubydoc.info/gems/ergo/frames)


## Ergo in a Hot Minute

To install, either use Rubygems directly:

```
  $ gem install ergo
```

Or add `gem "ergo"` to your Gemfile and run:

```
  $ bundle install
```

Create a `.ergo` directory in your project.

```
  $ mkdir .ergo
```

Edit the `.ergo/script.rb` file.

```
  $ vi .ergo/script.rb
```

And add the following example script to the file.

```ruby
  manifest = %w[bin/**/* lib/**/* *.md]

  state :need_manifest? do
    if File.exist?('MANIFEST')
      files = manifest.map{ |d| Dir[d] }.flatten
      saved = File.readlines('MANIFEST').map{ |f| f.strip }
      files != saved
    else
      true
    end
  end

  desc "update manifest"
  rule need_manifest? do
    files = manifest.map{ |d| Dir[d] }.flatten
    File.open('MANIFEST', 'w'){ |f| f << files.join("\n") }
  end

  desc "run my minitests"
  rule 'lib/**/*.rb' do |libs|
    $: << 'lib'
    files = Dir.glob('test/**/*_test.rb') 
    files.each{|file| require "./" + file}
  end
```

Now run it with:

    $ ergo

And there you go. Ergo, in a hot minute!


## A Couple of Extra Minutes

As the capable Ruby programmer, it probable doesn't require much explination
to understand the above code and what happend when you ran it. Just the
same it can help to go over it with the write terminology.

Of course, the rules in our example are simplistic and they make some basic
assumptions about a project, so you will want to modify these to suite your
needs (or dispose of them and write fresh). Nonetheless, this example
provides some clear examples of the basics of writing Ergo scripts.

In the example we first create a *state* called `update_manifest?`. It
simply checks to see if the list of files in the project's MANIFEST
file matches the project files expected to be there. Notice it returns
a boolean value, true or false. Along with this state we create a *rule*
that uses the state by calling the `update_manifest?` method. This method
was created by the state definition above. The *rule procedure* updates the 
MANIFEST file whenever the state return `true`, i.e. the manifest does
not have the expected content.

At the end of our example script we create an additional rule. This
one does not reference a defined state. Instead it create a *file state*
implicitly by passing a string argument to `rule`. A file state has a
very simple and very useful definition. It returns `true` whenever a
matching file has changed from one execution of `ergo` to the next.
In other words, per this example, whenever a Ruby file in the `lib` 
directory changes, Ergo is going to run the units tests in the `test` 
directory.

Okay, so now we have a example rules script and have a basic grasp of
how it works. And we know we can run the rules simple by invoking the
`ergo` command on command line. But if we want to have ergo run
automatically periodically, we can pass it the number of seconds to
wait between runs via the `-a/--auto` option.

    $ ergo -a 180

See it pays to read all the way to the end ;)


## Copyright & License

Ergo is copyrighted open-source software.

  Copyright (c) 2011 Rubyworks. All rights reserved.

It is modifiable and redistributable under the terms of the *BSD-2-Clause* license.

See the enclosed LICENSE.txt file for details.

(火)
