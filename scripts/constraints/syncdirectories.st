#!env stsh
#-sync:<ref>source to:<ref>target
sourceScheme ← source asScheme.
copier := MPWRESTCopyStream streamWithSource:sourceScheme target:target asScheme.
sourceScheme setLog:copier.
runLoop run.
