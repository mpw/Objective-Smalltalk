

scheme BlogSite {
    var postsList.
    -initWithBundle:aBundle {
       this:postsList ← #STTemplateStore{
       	                   templateNames: (#STRootMapper{} →  #TemplateNames{ baseName: 'Blog' }),
	                   bundle: aBundle } → #EntityList{ entityClass: Post, initialData: (self initialData) }.
       self.
    }


    -initialData {
      [
          #Post{ id: 1, title: 'Sails is very Cool' , body:'Sailing the Web'},
          #Post{ id: 2, title: 'Architecture' , body:'for the win'},
          #Post{ id: 3, title: 'Objective-S' , body:'Small Teams for large projects'},
      ] mutableDictionaryByKey:'id'.
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
}
