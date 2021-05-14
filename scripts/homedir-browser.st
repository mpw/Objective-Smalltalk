scheme:home := ref:file:{env:HOME} asScheme.      

browser := MPWBrowser new 

browser setRef: ref:home:/       
home:/    
browser description       
browser openInWindow:'Home'.  