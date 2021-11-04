#!env stsh
#-<void>mount: theScheme
framework:SchemeFUSE load.

scheme:txt := #MPWExtensionMapper{ #extension: 'txt' , #source: scheme:{theScheme}  }.


fs := scheme:txt  mountAt: ref:/Volumes/SchemeFS.

shell runInteractiveLoop

fs unmount.
