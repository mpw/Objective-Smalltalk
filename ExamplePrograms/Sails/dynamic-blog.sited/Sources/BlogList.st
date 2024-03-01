class BlogEntry {
	var id.
	var title.
	var body.
        -description {
	    "Entry '{this:title}' body '{this:body}'".
        }
        +id:newId {
             new ← self new autorelease.
             new setId:newId.
             new.
        }
}.


scheme BlogList {
    var entriesById.
    var maxId.
    -entries  {
          this:entriesById allValues.
    }

    -initialData {
        entries ← [
          #BlogEntry{ id: 1, title: 'Sails is very Cool' , body:'Sailing the Web'},
          #BlogEntry{ id: 2, title: 'Architecture' , body:'for the win'},
          #BlogEntry{ id: 3, title: 'Objective-S' , body:'Small Teams for large projects'},
        ].
        this:maxId ← entries count.
        NSMutableDictionary alloc initWithObjects: entries forKeys: entries collect id | autorelease.
    }


    -initWithBundle:aBundle {
	self ← super init.
        this:entriesById ← self initialData.
        this:maxId ← this:entriesById count.
        self.
    }
    -nextId {
        this:maxId ← this:maxId + 1.
        this:maxId.
    }
    -init {
	self initWithBundle:nil.
    }

    /:id/delete {
       get {
	    this:entriesById removeObjectForKey: id intValue.
 	    ref://posts/ .
       }
    }

    /:id/edit {
       get {
	         this:entriesById objectForKey:id intValue.
       }
    }
    -at:uri post:data {
             stdout println:"POST of a blog post at {uri} data: {data}".
	     components := uri path componentsSeparatedByString:'/'.
             id ← components[2].
             thePost ←nil.
             id = 'post' ifTrue: {
                   thePost ← BlogEntry id: self nextId.
             } ifFalse: {
                    thePost ← this:entriesById objectForKey:id intValue.
            }.
            data allKeys do: { :key | 
                 thePost setValue: (data objectForKey:key) forKey:key.
            }.
	    self at:thePost id stringValue put:thePost.
	    ref://posts/ .
    }
    
    /  {
       get {
          // a comment
          // self applyContext: #{ entries: this:entries }  toTemplateNamed:'BlogList.html'.
          this:entries.
       }
    }
    /new { get {
          "".
    } }
    /:id {
       get {
          this:entriesById objectForKey:id intValue.
       }
       put { 
          this:entriesById setObject:newValue forKey: id intValue.
       }
    }
   /*:p {
       get {
          "<html><body>This posts fallback page: {p}.<p><a href='/posts/'>Go to posts</a></body></html>".
       }
    }

}.
