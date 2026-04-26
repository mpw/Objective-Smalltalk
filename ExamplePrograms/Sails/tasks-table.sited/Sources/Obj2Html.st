
scheme Obj2Html : MPWMappingStore {
     -mapRetrievedObject:anObject forReference:aRef {
                var hs ← HTMLGenerator stream.
                hs html:{
                  hs body:{
                    hs ! anObject.
                  }.
                }.
                hs target target.

     }
}.


