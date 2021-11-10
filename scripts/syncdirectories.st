#!env stsh
#-sync:<ref>source to:<ref>target
sourceScheme ← source asScheme.
copier := MPWRESTCopyStream streamWithSource:sourceScheme target:target asScheme.
watcher := #MPWFileChangesStream{ #reference: source } → #MPWPathMapper{ #prefix: source } → copier.
watcher start.
runLoop run.
