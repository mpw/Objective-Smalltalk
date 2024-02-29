
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
    -applyContext:aContext toTemplateNamed:templateName {
	templateString := (this:bundle resources at:templateName )  stringValue. 
	templateString evaluateAsTemplateWith: aContext.
    }
    /posts {
      get {
	stdout println:'aux (base) forwarder'.
	theObject ← postsList:/ .
	template ← templateNames:/ .
        self applyContext: theObject  toTemplateNamed:template.
      }
    }
    /posts/*:rest {
      get {
        rest = '' ifTrue:{
	   rest ← '/'.
        }.
	stdout println:"main forwarder: '{rest}'".
        // postsList:{rest}.               does not work, rest is treated as a single path component
					// but actually contains multiple pathc components
	// this:postsList at:rest.         also works
	theObject ← ref:postsList:{rest} value.
        stdout println:'got the object: ',theObject.
	template ← this:templateNames at:rest.
        stdout println:'name schemes: ',scheme:templateNames.
        stdout println:template.
        result ← nil.
        (theObject isKindOfClass: MPWBinding class) ifTrue:{
            result ← theObject. 
        } ifFalse: {
 	    result ← self applyContext: theObject  toTemplateNamed:template.
        }.
	stdout println:'got result:', result.
	result.
      }
    }
    
    /*:p {
       get {
          '<html><body>This is the dynamic blog, fallback page  and it is being called.<p><a href="posts/">Go to posts</a></body></html>'.
       }
    }
}.
