
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
        /tasks/newItem {
		post {
                    this:taskList insertObject: #Task{ title: ((newValue at:'title') ) } atIndex:0. 
		    stdline ! ref:this:/ .
		    ref:special:/ .
                }
        }
        
        -renderFormOn: html {
                   html form:{ 
                       html input:'' attributes:#{ type: 'text' , name: 'title' } .
                       } attributes:#{ hx-post:'/tasks/newItem'    } .
         }
        -renderTableOn: html {
                   html div: {
                          html ! this:taskList.
                   } attributes: #{}.
         }

       /item/:row/:columnName {  put { 
            stdout println:'put at item'.
            newValue count > 0 ifTrue: {
                   newValue ←newValue at: columnName.
            } ifFalse: { 
                   newValue ← false.
            }.
            newValue = 'on' ifTrue: {
                    newValue ← true.
            }.
            var column ← this:taskList columnForKey: columnName.
            stdout println: column.
            stdout println: newValue.
 	    column replaceObjectAtIndex: row intValue withObject: newValue.
            stdout println: 'did replace'.
            ref:this:/tasks/items .
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
                    self renderFormOn: hs.
                    self renderTableOn: hs.

                  } attributes: #{ id: 'body' , hx-target: '#body'  } .
                }.
                stdline ! 'got tasks'.
                hs target target.

     } }  
     /  { get { ref:this:/tasks/items } }
}.

