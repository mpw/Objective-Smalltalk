#!/usr/local/bin/stsh
#-<void>serve:<ref>dir
framework:ObjectiveHTTPD load.
server := MPWSchemeHttpServer new.
server server setPort:8088.
base := dir asScheme.
cache := base cachedBy: MPWSiteMap scheme.

server setScheme: cache .
#server setScheme: base.

server start:nil.
shell runInteractiveLoop.

