
scheme TableStore : MPWMappingStore {
        var bundle.
        -initWithBundle:aBundle {
           self ← super init.
           this:bundle ← aBundle.

           self. 
        }
        /htmx.js { 
               get {
                   this:bundle resources at:'htmx.js'.
               }
         }
        /style.css { 
               get {
                   this:bundle resources at:'style.css'.
               }
         }
}.

