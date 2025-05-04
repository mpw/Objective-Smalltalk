#!env st
framework:ObjectiveHTTPD load.

scheme Time {
  /time { get { NSDate date stringValue. } }
}.
server ← #MPWSchemeHttpServer{ port: 8090 } → Time scheme.
stdout println:'Serving on port: 8090'.
server run.
