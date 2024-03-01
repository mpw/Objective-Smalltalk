
class RootMapper : MPWMappingStore {
    -mapReference:ref {
       ref path = '' ifTrue:{
           ref ← ref:/ reference.
        }.  
	ref.
    }
}.

class Templater : MPWMappingStore {
    var templateNames.
    var bundle.
    -applyContext:aContext toTemplateNamed:templateName {
	templateString := (this:bundle resources at:templateName )  stringValue. 
	templateString evaluateAsTemplateWith: aContext.
    }
    -mapRetrievedObject:anObject forReference:ref {
         template ← this:templateNames at:ref.
         (anObject isKindOfClass: MPWBinding class) ifFalse:{
            anObject ← self applyContext: anObject  toTemplateNamed:template.
         }.
  	 anObject.
     }
}.

scheme BlogSite {
    var postsList.
    var templateNames.
    var bundle.
    -initWithBundle:aBundle {
       list ← BlogList alloc initWithBundle:aBundle | autorelease.
       this:templateNames ← RootMapper storeWithSource: TemplateNames store.
       templater ← Templater storeWithSource:list.
       templater setTemplateNames: this:templateNames.
       templater setBundle:aBundle.

       this:postsList ← RootMapper storeWithSource: templater.
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
        ref://posts/ .
      }
    }
    /posts/*:rest {
      get {
	result ← ref:postsList:{rest} value.
      }
    }
    
    /*:p {
       get {
          '<html><body>This is the dynamic blog, fallback page  and it is being called.<p><a href="posts/">Go to posts</a></body></html>'.
       }
    }
}.
