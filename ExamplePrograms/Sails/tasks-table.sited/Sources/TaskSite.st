
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
                stdline ! 'POST value: ', value.
                ref:var:/tasks. 
         }
        -at:uri post: value  {
                bozoNewAt:Post: .
                stdline ! value.
                this:taskList insertObject: #Task{ title: value at:'title' } atIndex:0. 
		stdout ! this:taskList. 
                'site:/tasks/'.
         }
        /newTask {
		post {
                    this:taskList insertObject: #Task{ title: newValue at:'title' } atIndex:0. 
                    ref:site:/tasks.
                }

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
                   hs form:{ 
                       hs input:'' attributes:#{ type: 'text' , name: 'title' } .
                       hs input:'' attributes:#{ type: 'submit' , value:'create' } .
                       hs input:'' attributes:#{ type: 'hidden' , name:'verb', value:'post' } .
                       } attributes:#{ hx-post:'/newTask'    } .
                   } attributes: #{ id: 'body' , hx-target: '#body'  } .
                   hs ! this:taskList.
                }.
                stdline ! 'got tasks'.
                hs target target.
           }
       }
	/complete/:id {
		put {
			(this:taskDict at:id) setDone:true.
			self persist.
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

