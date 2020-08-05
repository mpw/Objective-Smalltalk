class MetaobjectPage : MPWHtmlPage
{
var analytics.
var style.
var navigationNames.
var navigationTargets.
-<void>renderNavigationOnST:aRenderer {

self navigationNames do:  [ :navName |
   self renderNavigationTo: navName  ref: (self navigationTargets objectForKey: navName )  on:aRenderer .
].
self renderNavigationTo:'Blog' ref:'http://blog.metaobject.com' on:aRenderer .

}

}.
