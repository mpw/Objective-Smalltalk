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
          #BlogEntry{ id: 1, title: 'Sails is very Cool' , body:'Sailing the Web'},
          #BlogEntry{ id: 2, title: 'Architecture' , body:'for the win'},
          #BlogEntry{ id: 3, title: 'Objective-S' , body:'Small Teams for large projects'},
        ].
        ids ← this:entries collect id.
        this:entriesById ← NSDictionary alloc initWithObjects: this:entries forKeys: ids.
        this:bundle ← aBundle.
        self.
    }
    -applyContext:aContext toTemplateNamed:templateName {
	(this:bundle resources at:templateName )  stringValue evaluateAsTemplateWith: aContext.
    }
    -init {
	self initWithBundle:nil.
    }

    /:id/edit {
       get {
	         self applyContext: (this:entriesById objectForKey:id intValue)  toTemplateNamed:'BlogEdit.html'.
       }
    }
    -at:uri post:data {
             stdout println:"POST of a blog post at {uri} data: {data}".
	     "<html><body>Posted data to {id}  data: {data}</body></html>"
    }
    
    /  {
       get {
          // a comment
          self applyContext: #{ entries: this:entries }  toTemplateNamed:'BlogList.html'.
       }
    }
    
    /:id {
       get {
          self applyContext: (this:entriesById objectForKey:id intValue)  toTemplateNamed:'BlogEntry.html'.
       }
       put { 
	  "PUT something".
       }
    }
   /*:p {
       get {
          '<html><body>This posts fallback page: {p}.<p><a href="/posts/">Go to posts</a></body></html>'.
       }
    }

}.
