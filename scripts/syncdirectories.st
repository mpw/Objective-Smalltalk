#!env stsh
#-sync:<ref>source to:<ref>target
watcher := MPWFileChangesStream alloc initWithDirectoryPath: source path.
copier := MPWRESTCopyStream streamWithSource:source asScheme target:target asScheme.
watcher → #MPWPathMapper{ #prefix: source } → copier.
watcher start.
runLoop run.
