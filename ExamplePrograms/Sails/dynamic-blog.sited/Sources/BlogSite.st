
scheme BlogSite {
    var postsList.
    -init {
       this:postsList ← BlogList new.
       self.
    }
    -schemeNames { 
	[ 'postsList' ].
    }
    /posts/*:rest { get {
	postsList:{rest}.
    }}
    
    /*:p { get {
          "This is the dynamic blog".
       }
    }
}
