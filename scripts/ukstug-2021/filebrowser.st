scheme:dict := #MPWPlistStore{ #a: '1', #b: '2' }.  


browser ← #MPWFileBrowser{ #store: (ref:file:/Users/marcel/programming asScheme)  }.
browser view openInWindow:'Plist'  .   <NSWindow: 0x14865ef50>