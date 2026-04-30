
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
        -post:value at:uri {
                stdline ! 'POST value'.
                ref:var:/tasks. 
         }
        -at:uri post: value  {
                stdline ! 'POST value'.
                ref:var:/tasks. 
         }
         /newTask {
             post { 
                stdline ! 'newTask'.
                ref:var:/tasks/ .
             }
        }
	/tasks { 
	   get { 
                var hs ← STHTMLGenerator stream.
                hs html:{
                  hs head:{
                     hs title:'Tasks List'.
                     hs link:#{ rel: 'stylesheet',  type: 'text/css',  href: 'style.css'}.
                  }.
                  hs body:{
                    hs ! 'This is the task list'.
                    hs br: nil.
                    hs ! ''.
                    hs br: nil.
                   hs form:{ 
                       hs input:'' attributes:#{ type: 'text' , name: 'title' } .
                       hs input:'' attributes:#{ type: 'submit' , value:'create' } .
                       } attributes:#{ method: 'post' , action: 'newToDo'  } .
                   } .
                   hs ! this:taskList.
                }.
                hs target target.
           }
       }
	/complete/:id {
		put {
			(this:taskDict at:id) setDone:true.
			self persist.
		}
	}
        /style.css { 
               get {
                   this:bundle resources at:'style.css'.
               }
         }
	/task/:id {
		get {
			this:taskDict at:id .
		}
		put {
			this:taskDict at:id put:newValue.
			self persist.
		}
	}
}.

