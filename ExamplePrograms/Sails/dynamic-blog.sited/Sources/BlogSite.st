
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
    -initWithBundle:aBundle {
       this:postsList ← #Templater{
       	                   templateNames: (#RootMapper{} →  #TemplateNames{ baseName: 'Blog' }),
	                   bundle: aBundle } → #BlogList{}.
       self.
    }
    -init {
        self initWithBundle:nil.
    }
    -schemeNames { 
	[ 'postsList' ].
    }
    -at:ref  post:data {
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
          '<html><body>This is the dynamic blog, fallback page  and it is being called.<p><a href="/posts/">Go to posts</a></body></html>' asData.
       }
    }
    +testSelectors { [ 'testSomething' ]. }

    +<void>testSomething {
         3 assertEqual: 3 msg:'not'.
    }
}.
