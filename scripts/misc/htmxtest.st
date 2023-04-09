#!env stsh
#
#


framework:ObjectiveHTTPD load.
html := file:clickme.htmx .
scheme SiteMap {
  /hello { |= {  file:clickme.htmx. } }
  /clicked { |= {  "Was clicked!". } }
}.
stdout println:SiteMap.
SiteMap serveOnPort:8090.
shell runInteractiveLoop.

