#!env stsh
#-sync:<ref>source to:<ref>target
watcher := #MPWFileChangesStream{ #reference: source }.
copier := MPWRESTCopyStream streamWithSource:source asScheme target:target asScheme.
watcher → #MPWPathMapper{ #prefix: source } → copier.
watcher start.
runLoop run.
