class MPWSiteServer : NSObject
{
var server.
var sitemap.
var templater.
var renderer.
var cache.
var interpreter.
var methodServer.
var _methodDict.
-<void>setupInterpreter {

  stdout println:'set interpreter'.


  map := self sitemap sitemap.
  stdout print:'sitemap -> '. stdout println: map.

  scheme:dynamic := map.
  scheme:hello := map.
  scheme:dynamic := map.  


 scheme:page :=  MPWBlockFilterScheme filterWithSource: scheme:rsrc idFilter: [ :name | (name hasSuffix:'/') ifTrue:[ name:=name substringToIndex:name length - 1 ]. name, '.html'. ] valueFilter: [ :value |  (MPWPlainHtmlContent alloc initWithContentData:value ) autorelease. ] .

  scheme:markdown :=  MPWBlockFilterScheme filterWithSource: scheme:rsrc idFilter: [ :name | (name hasSuffix:'/') ifTrue:[ name:=name substringToIndex:name length - 1 ]. name, '.markdown'. ] valueFilter: [ :value |  (MPWPlainHtmlContent alloc initWithContentData:value markdownToHtml ) autorelease. ] .
  stdout print:'scheme:dynamic -> '. stdout println: scheme:dynamic.
}

}.
