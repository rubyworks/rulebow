# RELEASE HISTORY

## 0.3.0 / 2013-02-13

Major release removes tasks. There are only rules now! In
addition *books* have been added which allow rules to be
grouped together.

Changes:

* Deprecate tasks.
* Add rulebooks.


## 0.2.0 / 2013-02-12

This is the last version with tasks. Tasks are being deprecated
for two reasons: a) they add a great deal of complexity to the
syntax and the implementation via their need for dependencies;
and b) tasks have proven to be an excuse for poorly designed 
rules, which, if properly written, would do the job just as well
if not better than any task. So it was decided that if tasks are
needed, then they should be provided via dedicated task system,
not via the rules system.

Changes:

* Default rule file is now `.fire/rules.rb` or `rules.rb`.
* Rules can depend on tasks using same hash notation as tasks.
* Modified the `#rule` method to define file rules given a string.
* Deprecated the `file` method for defining file rules.


## 0.1.0 / 2012-04-10

This is the initial release of Fire. Fire is state and rules-based
continuous integration and build tool.

Special thanks to Ari Brown for letting us take over the fire gem
for this project. "Fire" is perfect fit.

Changes:

* Happy first release day!

