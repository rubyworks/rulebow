# Fire 火

[Homepage](http://rubyworks.github.com/fire) /
[Report Issue](http://github.com/rubyworks/fire/issues) /
[Source Code](http://github.com/rubyworks/fire) /
[IRC Channel](http://chat.us.freenode.net/rubyworks)

***"Logic programming meets the build tool."***

Fire is a build tool that promotes continuous integration via logic
programming. With Fire, the Ruby developer defines rules and state
conditions. The rules are applied when their state conditions are
met. Through repetitive application, this allows a project to all
but manage itself.

Fire is not complicated. It goes not require a bazillion plug-ins.
Although some external tools can be helpful and used with it, and
it makes some procedures more convenient --for example it makes
FileUtils methods directly available in the build script context,
mostly it just trusts the developer to know how to write the build
scripts they need.

Below you will find a brief "Hot Minute" guide for getting up and
running with Fire quickly. It's just enough to give you familiarity
the basic ideas of Fire and how to start putting it to good use.
For more detailed instruction, explanation of terms and how the
dickens does it work under-the-hood, please consider any of the
following resources.

* [Overview of Fire](https://github.com/rubyworks/fire/wiki/Overview-of-Fire)
* [Helpful FAQs](https://github.com/rubyworks/fire/wiki/FAQ)
* [Fire Recepies](https://github.com/rubyworks/fire/wiki/Fire-Recipes)
* [API Documentation](http://rubydoc.info/gems/fire/frames)


## Fire in a Hot Minute

To install, either use RubyGems directly:

```
  $ gem install fire
```

Or add `gem "fire"` to your Gemfile and run:

```
  $ bundle install
```

Creat a `Rulebook` file in your project.

```
  $ vi Rulebook
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

    $ fire

And there you go. Fire, in a hot minute!


## A Few More Minutes

As the capable Ruby programmer, it probable doesn't require much explanation
to understand the above code and what happened when you ran it. Just the
same it can help to go over it with the proper terminology. Of course,
the rules in our example are simplistic and they make some basic
assumptions about a project, so you will want to modify these to suite your
needs (or dispose of them and write fresh). Nonetheless, this example
provides some clear examples of the basics of writing Fire scripts.

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
matching file has changed from one execution of `fire` to the next.
In other words, per this example, whenever a Ruby file in the `lib` 
directory changes, Fire is going to run the units tests in the `test` 
directory.

Okay, so now we have a example rules script and have a basic grasp of
how it works. And we know we can run the rules simple by invoking the
`fire` command on command line. But if we want to have fire run
automatically periodically, we can pass it the number of seconds to
wait between runs via the `-a/--auto` option.

    $ fire -a 180

See it pays to read all the way to the end ;)


## Contributing

The Fire [repository](http://github.com/rubyworks/fire) is hosted on GitHub.
If you would like to contribute to the project (and we would be over joyed
if you did!) the rules of engagements are very simple.

1. Fork the repo.
2. Branch the repo.
3. Code and test.
4. Push the branch.
4. Submit pull request.


## Copyrights

Fire is copyrighted open-source software.

    Copyright (c) 2011 Rubyworks. All rights reserved.

It is modifiable and redistributable under the terms of the
[BSD-2-Clause](http::/spdx.org/licenses/BSD-2-Clause) license.

See the enclosed LICENSE.txt file for details.

(由)
