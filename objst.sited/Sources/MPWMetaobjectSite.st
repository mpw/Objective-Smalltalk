class MPWMetaobjectSite : NSObject
{
var productsDict.
var newsItems.
var sitemap.
var renderer.
-createTemplater {
    templater := MPWTemplater scheme .
    template := MetaobjectPage alloc init autorelease.
    template setNavigationNames: self rootLevelNames.
    template setNavigationTargets: self nameToTargetMap.
    templater setTemplate:template .
    templater template setSource:self .
    templater setSourceScheme: self overallRawSite.

    templater.
}
-overallRawSite {
	( scheme:markdown before: scheme:page) cachedBy:scheme:dynamic.
}
-parseProductsDict {
    stdout println:'--- parseProductsDict ----'.
    stdout println: scheme:rsrc. 
    stdout println:'did have the scheme'.
    defsDict := rsrc:products.plist value .
    stdout println:'did get products'.
    appStoreDict := rsrc:appStoreLinks.plist value .
    productNames := defsDict allKeys .
    products := MPWProductDescription collect productWithName:productNames each .
    products do setSource:self .
    versions := defsDict collect objectForKey: productNames each .
    appStoreLinks := appStoreDict collect  objectForKey: productNames each .
    products do setCurrentVersion: versions each .
    products do setAppStoreURL: appStoreLinks each .
    NSDictionary dictionaryWithObjects:products forKeys:productNames .
}
-productNames {
   #(  'BookLightning', 'PdfCompress', 'TextLightning', 'PostView', 'MusselWind', 'TouchScript' )
}
-rootLevelNames {
 #( 'Home', 'Products' ) arrayByAddingObjectsFromArray: self staticRootLevelPageNames .
}
-<void>setupSite {
  self setProductsDict: self parseProductsDict .
  stdout println:'setupSite, did parseProductsDict'.
  dynamic:/  := MPWMainPage pageWithStaticContentNamed:'Main' source:self .
  stdout println:'setupSite, will parse news'.
  dynamic:/  setNewsItems: ( MPWProductNewsItem collect newsItemsWithDict: ( rsrc:news.newsplist value  ) each site:self ) .
  stdout println:'setupSite, did parse news'.

  dynamic:/Products := (MPWProductListPage alloc initWithProducts: (self productsDict collect objectForKey: self productNames each )) autorelease .
}
-staticRootLevelPageNames {
 #(   'Services', 'Experience', 'Research',  'Technology',  'Contact' )
}
-<void>writeToDirectory:baseDirString {
   (self rootLevelNames arrayByAddingObject:'/') do: [ :name |
	  page := self renderer get:name.
          targetPath := baseDirString , name, '/index.html'.
          self mkDirs:targetPath.
	  page writeToFile: targetPath atomically:1.
    ].  
}

}.
