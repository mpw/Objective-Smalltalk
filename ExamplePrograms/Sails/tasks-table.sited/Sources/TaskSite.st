
scheme TaskSite : MPWMappingStore {
        var taskList.
        -initWithBundle:aBundle {
           self ← super init.
           this:taskList ←  #MPWObjectArrayTable[
                    #Task{ id:0, title: 'Submit paper', done: true },
                    #Task{ id:1, title: 'Write code', done: true },
                    #Task{ id:2, title: 'Write thesis', done:false } ].
           this:taskList columns at:0 | setVisible: false.
           var columns ← this:taskList visibleColumns.
           this:taskList setVisibleColumns: [ columns[1], columns[0] ].

           self. 
        }
        -setupSite {

        }
        -createTemplater {
	   Obj2Html store.
        }
	/tasks { 
	   get { 
                var hs ← STHTMLGenerator stream.
                hs html:{
                  hs body:{
                    hs ! this:taskList.
                  }.
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
	/task/:id {
		get {
			this:taskDict at:id .
		}
		put {
			this:taskDict at:id put:newValue.
			self persist.
		}
	}
	-<void>persist {
		source:tasks := self taskList.
	}
}.

