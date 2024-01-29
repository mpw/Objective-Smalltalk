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
    var entriesById.

    -init {
	self ← super init.
        this:entries ← [
              #BlogEntry{ #id: 1, #title: 'Sails is Cool' , #body:'Hello World'},
              #BlogEntry{ #id: 2, #title: 'Architecture for the win' , #body:'Hello World'},
              #BlogEntry{ #id: 3, #title: 'Objective-S: small teams for large projects' , #body:'Hello World'},
        ].
        ids ← this:entries collect id.
        this:entriesById ← NSDictionary alloc initWithObjects: this:entries forKeys: ids.
        self.
    }
    /index  {
       get {
          this:entries.
       }
    }
    
    /:id {
       get {
          this:entriesById objectForKey:id intValue.
       }
       put { 
	  "PUT something".
       }
    }
}.
