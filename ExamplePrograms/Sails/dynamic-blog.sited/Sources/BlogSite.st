

scheme BlogSite {
    var postsList.
    -initWithBundle:aBundle {

       this:postsList ←  #STTemplateStore{ bundle:aBundle, templateName: 'Site.html' } →  
                         #STTemplateStore{ bundle: aBundle } →
                         #STEntityList{ entityClass: Post, initialData: (self initialData), location: '/posts/' }.
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
    /posts/*:rest {
      get {
	result ← ref:postsList:{rest} value.
      }
    }
    
    /*:p {
       get {
          "<html><body>This is the dynamic blog, fallback page  and it is being called via '{p}'.<p><a href='/posts/'>Go to posts</a></body></html>" asData.
       }
    }
    +testSelectors { [ 'testSomething' ]. }

    +<void>testSomething {
         3 assertEqual: 3 msg:'not'.
    }
}
