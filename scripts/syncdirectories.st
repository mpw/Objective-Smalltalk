#!env stsh
#-sync:<ref>sourceRef to:<ref>targetRef
targetStore := targetRef asScheme.
sourceStore := sourceRef asScheme.
watcher := MPWFileChangesStream alloc initWithDirectoryPath: sourceRef path.
watcher schedule.
copier := MPWRESTCopyStream streamWithSource:sourceStore target:targetStore.
prefixremover := MPWPathMapper new.
prefixremover setPrefix:sourceRef.

watcher → prefixremover → copier.
watcher start.
NSRunLoop currentRunLoop runInterruptibly.
shell runInteractiveLoop.
