#!env stsh
#-sync
sourceRef := ref:file:/private/tmp.
sourcePath := sourceRef path.
sourcePathLen := sourcePath length+1.
targetRef := ref:file:/Users/marcel/temp/
targetStore := targetRef asScheme.
watcher := MPWFileChangesStream alloc initWithDirectoryPath: sourceRef path.
watcher schedule.
sourceStore := sourceRef asScheme.
copier := MPWRESTCopyStream streamWithSource:sourceStore target:targetStore.
prefixremover := { :object |  MPWRESTOperation operationWithReference: (object reference path substringFromIndex:sourcePathLen) verb: object verb. }.
watcher → prefixremover → copier.
watcher start.
NSRunLoop currentRunLoop runInterruptibly.
shell runInteractiveLoop.
