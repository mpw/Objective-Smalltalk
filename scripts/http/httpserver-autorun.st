#!/usr/local/bin/stsh
#-<void>fileserver:<ref>dir
framework:ObjectiveHTTPD load.
httpserver := (MPWSchemeHttpServer serverOnPort:8081).

server := dir ⇨ httpserver.
httpserver.
