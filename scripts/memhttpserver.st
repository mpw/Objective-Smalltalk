#!/usr/local/bin/stsh
framework:ObjectiveHTTPD load.
scheme:site serveOnPort:8081.
stdout println:'site:<path> := value'.
shell runInteractiveLoop.
