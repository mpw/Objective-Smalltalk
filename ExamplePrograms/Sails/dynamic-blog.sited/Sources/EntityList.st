
scheme EntityList : STEntityList {
    /:id/delete {
       get {
	    this:entries removeObjectForKey: id intValue.
 	    ref://posts/ .
       }
    }

    /:id/edit {
       get {
	         this:entries objectForKey:id intValue.
       }
    }
    -at:uri post:data {
             stdout println:"POST of a blog post at {uri} data: {data}".
	     components := uri path componentsSeparatedByString:'/'.
             id ← components[2].
             thePost ←nil.
             id = 'post' ifTrue: {
                   id := self nextId.
                   thePost ← this:entityClass id: id.
             } ifFalse: {
                    thePost ← this:entries objectForKey:id intValue.
            }.
            data allKeys do: { :key | 
                 thePost setValue: (data objectForKey:key) forKey:key.
            }.
	    self:{id} :=  thePost.
	    ref://posts/ .
    }
    
    /  {
       get {
          this:entriesArray.
       }
    }
    /new { get {
          "".
    } }
    /:id {
       get {
          this:entries objectForKey:id intValue.
       }
       put { 
          this:entries setObject:newValue forKey: id intValue.
       }
    }
}
