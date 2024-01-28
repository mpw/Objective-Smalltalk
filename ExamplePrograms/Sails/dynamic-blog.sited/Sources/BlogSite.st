
scheme BlogSite {
    var postsList.
    -init {
       this:postsList ← BlogList new.
       self.
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
          "This is the dynamic blog, fallback page".
       }
    }
}
