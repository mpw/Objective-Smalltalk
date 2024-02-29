
class Templater : MPWMappingStore {

}.

scheme BlogSite {
    var postsList.
    var templateNames.
    var bundle.
    -initWithBundle:aBundle {
       list ← BlogList alloc initWithBundle:aBundle | autorelease.
       this:templateNames ← TemplateNames store.
       templater ← Templater storeWithSource:list.
       this:postsList ← templater.
       this:bundle ← aBundle.
       self.
    }
    -init {
        self initWithBundle:nil.
    }
    -schemeNames { 
	[ 'postsList', 'templateNames' ].
    }
    -at:ref  post:data {
	stdout println:'post arrived at BlogSite'.
	this:postsList at:ref post:data.
      }
    /posts {
      get {
//	postsList:/.
	templateNames:/.
      }
    }
    /posts/*:rest {
      get {
        // postsList:{rest}.               does not work, rest is treated as a single path component
					// but actually contains multiple pathc components
	// this:postsList at:rest.         also works
	// ref:postsList:{rest} value.
	ref:templateNames:{rest} value.
      }
    }
    
    /*:p {
       get {
          '<html><body>This is the dynamic blog, fallback page  and it is being called.<p><a href="posts/">Go to posts</a></body></html>'.
       }
    }
}.
