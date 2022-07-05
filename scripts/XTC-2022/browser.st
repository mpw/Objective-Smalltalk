#MPWFileBrowser{ #store: scheme:defaults } openInWindow:'Defaults'.  


browser := MPWMethodBrowser alloc initWithDefaultNib. 
browser setMethodStore: smalltalk  methodStore. 

browser view window makeKeyAndOrderFront:nil  