# RULEBOW

[Homepage](http://rubyworks.github.com/rulebow) -
[Report Issue](http://github.com/rubyworks/rulebow/issues) -
[Source Code](http://github.com/rubyworks/rulebow) -
[IRC Channel](http://chat.us.freenode.net/rubyworks)

***"Hey, you got logic in my build tool!"***

Rulebow is a build tool that promotes continuous integration via logic
programming. With Rulebow, the Ruby developer defines *rules* and state
conditions called *facts*. The rules are applied when their conditions
are met. Through repetitive application, this allows a project to all
but manage itself.

Rulebow is not complicated. It does not require a bazillion plug-ins.
Although some external tools can be helpful and used with it, and
it makes some procedures more convenient. For example, it makes
FileUtils methods directly available in the build script context.
Mostly it just trusts the developer to know how to write the build
scripts they need.

Below you will find a brief "Hot Minute" guide for getting up and
running with Rulebow quickly. It's just enough to give you familiarity
the basic ideas of Rulebow and how to start putting it to good use.
For more detailed instruction, explanation of terms and how the
dickens does it work under-the-hood, please consider any of the
following resources.

* [Overview of Rulebow](https://github.com/rubyworks/rulebow/wiki/Overview)
* [Helpful FAQs](https://github.com/rubyworks/rulebow/wiki/FAQ)
* [Rulebow Recepies](https://github.com/rubyworks/rulebow/wiki/Recipes)
* [API Documentation](http://rubydoc.info/gems/rulebow/frames)


## Rulebow in a Hot Minute

To install, either use RubyGems directly:

```
  $ gem install rulebow
```

Or add `gem "rulebow"` to your Gemfile and run:

```
  $ bundle
```

Creat a `Rulebook` file in your project.

```
  $ vi Rulebook
```

And add the following example script to the file.

```ruby
ruleset :default => [:manifest, :test]

ruleset :manifest do
  desc "update manifest"

  globs = %w[bin/**/* lib/**/* *.md]

  fact :need_manifest? do
    if File.exist?('MANIFEST')
      files = globs.map{ |d| Dir[d] }.flatten
      saved = File.readlines('MANIFEST').map{ |f| f.strip }
      files != saved
    else
      true
    end
  end

  rule :need_manifest? do
    files = globs.map{ |d| Dir[d] }.flatten
    File.open('MANIFEST', 'w'){ |f| f << files.join("\n") }
  end
end

ruleset :test do
  desc "run my minitests"

  rule 'lib/**/*.rb' do |libs|
    $: << 'lib'
    files = Dir.glob('test/**/*_test.rb') 
    files.each{|file| require "./" + file}
  end
```

Now run it with:

    $ bow

And there you go. Rulebow, in a hot minute!


## A Few More Minutes

As the capable Ruby programmer, it probable doesn't require much explanation
to understand the above code and what happened when you ran it. Just the
same, it can help to go over it with the proper terminology. Of course,
the rules in our example are simplistic and they make some basic
assumptions about a project, so you will want to modify these to suite your
needs (or dispose of them and write fresh). Nonetheless, this example
provides some clear examples of the basics of writing Rulebow scripts.

The first line in the script defines the defauly ruleset. This is the
ruleset the is executes when no specific ruleset is designated on
the command line. In this case we see that it simply depends on two
other rulesets, `test` and `manifest`.

Nex in the example we create the `manifest` ruleset. In it we first
create a *state* called `update_manifest?`. It simply checks to see
if the list of files in the project's MANIFEST file matches the project
files expected to be there. Notice it returns a boolean value, true or
false. Along with this state we create a *rule* that uses the state by
calling the `update_manifest?` method. This method was created by the
state definition above. The *rule procedure* updates the MANIFEST file
whenever the state returns `true`, i.e. the manifest does not have the
expected content.

At the end of our example script we create an additional ruleset. This
one does not reference a defined state. Instead it creates a *file state*
implicitly by passing a string argument to `rule`. A file state has a
very simple and very useful definition. It returns `true` whenever a
matching file has changed from one execution of `rulebow` to the next.
In other words, per this example, whenever a Ruby file in the `lib` 
directory changes, Rulebow is going to run the units tests in the `test` 
directory.

Okay, so now we have an example rulebook and have a basic grasp of
how it works. And we know we can run the rules simple by invoking the
`rulebow` command on the command line. But if we want to have rulebow run
automatically periodically, we can pass it the number of seconds to
wait between runs via the `-a/--auto` option.

    $ bow -a 180

See it pays to read all the way to the end ;)


## Contributing

The Rulebow [repository](http://github.com/rubyworks/rulebow) is hosted on GitHub.
If you would like to contribute to the project (and we would be over joyed
if you did!) the rules of engagements are very simple.

1. Fork the repo.
2. Branch the repo.
3. Code and test.
4. Push the branch.
4. Submit pull request.


## Copyrights

Rulebow is copyrighted open-source software.

    Copyright (c) 2011 Rubyworks. All rights reserved.

It is modifiable and redistributable under the terms of the
[BSD-2-Clause](http::/spdx.org/licenses/BSD-2-Clause) license.

See the enclosed LICENSE.txt file for details.

(火 由)
