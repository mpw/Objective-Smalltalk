#!env st
framework:ObjectiveHTTPD load.
framework:Sails load.


class Task {
	var id.
	var <bool> done.
	var title.
        -stringId { this:id stringValue. }
	-description { "Task: {this:title} done: {this:done}". }
        -checked {  this:done ifTrue:'checked' ifFalse:''. }
}

taskList ← #MPWObjectArrayTable[
     #Task{ id:0, title: 'Submit paper', done: true },
     #Task{ id:1, title: 'Write code', done: true },
     #Task{ id:2, title: 'Write thesis', done:false } ].

stdout println: taskList. 
taskList columns at:0 | setVisible: false.
columns ← taskList visibleColumns.
taskList setVisibleColumns: [ columns[1], columns[0] ].


class HTMLGenerator : STHTMLGenerator {
}.

scheme Tasks : MPWMappingStore {
        var taskList.
	/tasks { 
	   get { 
	       this:taskList.
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

scheme Obj2Html : MPWMappingStore {
     -mapRetrievedObject:anObject forReference:aRef {
                var hs ← HTMLGenerator stream.
                hs html:{ 
                  hs body:{
		    hs ! anObject.
                  }.
		}.
                hs target target.

     }
}.

todo ← #Obj2Html{ } → #Tasks{ #taskList: taskList }.
server ← #MPWSchemeHttpServer{ scheme: todo , #port: 8082 }.
server server setThreadPoolSize:1.

scheme:todo := todo.
server start.
stdout println:'number of tasks: ', todo source taskList count stringValue.
stdout println:'port: ', server port stringValue.
shell runInteractiveLoop.

