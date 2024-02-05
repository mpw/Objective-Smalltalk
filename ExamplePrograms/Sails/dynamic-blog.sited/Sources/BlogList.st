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

    -initWithBundle:aBundle {
	self ← super init.
        this:entries ← [
          #BlogEntry{ id: 1, title: 'Sails is Cool' , body:'Sailing the Web'},
          #BlogEntry{ id: 2, title: 'Architecture' , body:'for the win'},
          #BlogEntry{ id: 3, title: 'Objective-S' , body:'Small Teams for large projects'},
        ].
        ids ← this:entries collect id.
        this:entriesById ← NSDictionary alloc initWithObjects: this:entries forKeys: ids.
        this:bundle ← aBundle.
        self.
    }
    -init {
	self initWithBundle:nil.
    }

    /  {
       get {
          // a comment
          this:bundle resources at:'BlogList.html'.
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
