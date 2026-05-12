
scheme TaskSite : MPWMappingStore {
        var bundle.
        var taskList.
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

           self. 
        }
	-<void>persist {
		source:tasks := self taskList.
	}
        /newTask {
		post {
                    this:taskList insertObject: #Task{ title: ((newValue at:'title'), ' - newTask' ) } atIndex:0. 
		    ref:this:tasks.
                }
        }
        
        -renderForm: html {
                   html form:{ 
                       html input:'' attributes:#{ type: 'text' , name: 'title' } .
                       } attributes:#{ hx-post:'/newTask'    } .
         }

	/tasks { 
	   get { 
                var hs ← STHTMLGenerator stream.
                stdline ! 'get tasks'.
                hs html:{
                  hs head:{
                     hs title:'Tasks List'.
                     hs link:#{ rel: 'stylesheet',  type: 'text/css',  href: 'style.css'}.
                  }.
                  hs body:{
                    hs script:'' attributes:#{ src: 'htmx.js' }.
                    hs ! 'This is the task list'.
                    hs br: nil.
                    hs ! ''.
                    hs br: nil.
                    self renderForm: hs.
                    hs ! this:taskList.

                  } attributes: #{ id: 'body' , hx-target: '#body'  } .
                }.
                stdline ! 'got tasks'.
                hs target target.
           }
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
        /style.css { 
               get {
                   this:bundle resources at:'style.css'.
               }
         }
        /  {  get { ref:this:/tasks . } }     
}.

