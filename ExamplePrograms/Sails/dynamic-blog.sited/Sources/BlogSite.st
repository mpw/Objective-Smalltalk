
scheme BlogSite {
    var postsList.
    var bundle.
    -initWithBundle:aBundle {
       this:postsList ← BlogList alloc initWithBundle:aBundle | autorelease.
       this:bundle ← aBundle.
       self.
    }
    -init {
        self initWithBundle:nil.
    }
    -schemeNames { 
	[ 'postsList' ].
    }
    /posts {
      get {
	postsList:/.
      }
    }
    /posts/*:rest {
      get {
        // postsList:{rest}.               does not work, rest is treated as a single path component
					// but actually contains multiple pathc components
	// this:postsList at:rest.         also works
	ref:postsList:{rest} value.
      }
    }
    
    /*:p {
       get {
          '<html><body>This is the dynamic blog, fallback page  and it is being called.<p><a href="posts/">Go to posts</a></body></html>'.
       }
    }
}
