#!env stsh
#-sync:<ref>source to:<ref>target
sourceScheme ← source asScheme.
targetScheme ← target asScheme.

targetScheme |= sourceScheme.

runLoop run.
