
scheme TaskSite : MPWMappingStore {
        var bundle.
        var taskList.
        var tableStore.
        -schemeNames { [ 'tableStore' ] }
        -initWithBundle:aBundle {
           self ← super init.
           this:bundle ← aBundle.
           this:taskList ←  #MPWObjectArrayTable[
                    #Task{ id:0, title: 'Submit paper', done: true },
                    #Task{ id:1, title: 'Write code', done: true },
                    #Task{ id:2, title: 'Write thesis', done:false } ].
           this:taskList columns at:0 | setVisible: false.
           var columns ← this:taskList visibleColumns.
           this:taskList setVisibleColumns: [ columns[1], columns[0] ].
           this:tableStore ← #TableStore{ theList: this:taskList }.

           self. 
        }
	-<void>persist {
		source:tasks := self taskList.
	}
        /tasks/newItem {
		post {
                    this:taskList insertObject: #Task{ title: ((newValue at:'title') ) } atIndex:0. 
		    stdline ! ref:this:/ .
		    ref:this:/tasks/items .
                }
        }
        

       /tasks/item/:row/:columnName {  put { 
            stdout println:'put at item in tasks'.
            tableStore:item/{row}/{columnName} ← newValue.
            stdout println:'tasks in TaskSite:'.
            stdout println: this:taskList.
        }   get  { ref:this:/tasks/items .  } }
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
        /tasks/items {  get { 
                var hs ← STHTMLGenerator stream.
                hs setBasePath:'/tasks'.
                stdline ! 'get tasks'.
                hs html:{
                  hs head:{
                     hs title:'Tasks List'.
                     hs link:#{ rel: 'stylesheet',  type: 'text/css',  href: '/style.css'}.
                  }.
                  hs body:{
                    hs script:'' attributes:#{ src: '/htmx.js' }.
                    hs ! 'This is the task list'.
                    hs br: nil.
                    hs ! ''.
                    hs br: nil.
                    this:tableStore renderFormOn: hs.
                    this:tableStore renderTableOn: hs.

                  } attributes: #{ id: 'body' , hx-target: '#body'  } .
                }.
                stdline ! 'got tasks'.
                hs target target.

     } }  
     /  { get { ref:this:/tasks/items } }
}.

