# Fire (火)

{Homepage}[http://rubyworks.github.com/fire] /
{Report Issue}[http://github.com/rubyworks/fire/issues] /
{Source Code}[http://github.com/rubyworks/fire]


## Introduction

Fire is rules-based build tool and continuous integration system.
The spark that created Fire is "state-machine meets build tool".


## Instruction

Example of state/rule in `RuleFile`:

    # Mast handles manifest updates.

    state :manifest_outofdate do
      ! system "mast --recent"
    end

    rule manifest_outofdate do
      system "mast -u"
    end

File rules are triggered when a file has changed.

    file 'man/*.ronn' do |paths|
      system 'ronn ' + paths.join(' ')
    end

To run fire, well simple run fire:

    $ fire

For manual triggers Fire supports desc/task notation:

    desc "run unit tests"

    task :test do
      system "rubytest"
    end

Manual triggers are specified as a command argument.

    $ fire test


## Copyrights

Copyright (c) 2011 Rubyworks

Fire is distributable under the terms of the *BSD-2-Clause* license.

See LICENSE.txt for details.

