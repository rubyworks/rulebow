# Fire (火)

[Homepage](http://rubyworks.github.com/fire) /
[Report Issue](http://github.com/rubyworks/fire/issues) /
[Source Code](http://github.com/rubyworks/fire) /
[IRC Channel](http://chat.us.freenode.net/rubyworks)


Fire is a rules-based build tool and continuous integration system.
The spark that created Fire is "state-machine meets build tool".


## Instruction

Example of state/rule in `task/fire.rb`:

    # Mast handles manifest updates.

    state :manifest_outofdate do
      ! system "mast --recent"
    end

    rule manifest_outofdate do
      system "mast -u"
    end

File rules are triggered when a file has changed.

    rule 'man/*.ronn' do |paths|
      system 'ronn ' + paths.join(' ')
    end

To run simply use `fire`:

    $ fire

Abstract states can be defined by *not* supplying a block:

    state :abstract

But thie is not generally necessary, b/c a state if referenced that
does not yet exist, then an abstract state is created automatically.

    rule test do
      system "rubytest"
    end

States can also be given descriptions via the `desc' method.

    desc "run all unit tests"
    rule test do
      system "rubytest"
    end

Abstract states can be triggered manually on the command line
or in code.

    $ fire test

There are few was to manually trigger builds. For file rules, 
the `-n` option will cause the digest to be "null and void",
which will cause all files to appear out-of-date and thus be
triggered.

For manual triggers supports desc/task notation:

    desc "run unit tests"

    task :test do
      system "rubytest"
    end

Manual triggers are specified as a command argument.

    $ fire test

## Continious Integration

Fire can be run continously by running autofire. To set the 
interval use the `-w/--wait` option.

    $ autofire -w 60

This run fire every 60 seconds. To stop autofiring run autofire
again.


## Copyright & License

Copyright (c) 2011 Rubyworks

Fire is distributable under the terms of the *BSD-2-Clause* license.

See LICENSE.txt for details.

