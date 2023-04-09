#!env stsh
#-logChanges:<ref>source 
sourceScheme ← source asScheme.
sourceScheme setLog:stdout.
runLoop run.
