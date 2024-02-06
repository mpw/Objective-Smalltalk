
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
        postsList:/{rest}.
      }
    }
    
    /*:p {
       get {
          "This is the dynamic blog, fallback page  and it is being called.".
       }
    }
}
