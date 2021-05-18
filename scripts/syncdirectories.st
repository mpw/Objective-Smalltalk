#!env stsh
#-sync:<ref>source to:<ref>target
copier := MPWRESTCopyStream streamWithSource:source asScheme target:target asScheme.
#MPWFileChangesStream{ #reference: source } → #MPWPathMapper{ #prefix: source } → copier.
watcher start.
runLoop run.
