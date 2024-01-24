class BlogEntry {
	var id.
	var title.
	var body.
        -description {
	    "Entry '{this:title}' body '{this:body}'".
        }
}.


scheme BlogList {
    var bundle.
    var entries.
    -init {
	self ← super init.
        this:entries ← [ #BlogEntry{ #title: 'First Blog' , #body:'Hello World'}].
        self.
    }
    
    /*:p {
       get {
          this:entries.
       }
       put { 
	  "PUT something".
       }
    }
}.
