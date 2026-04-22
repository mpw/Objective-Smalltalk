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

columns ← taskList columns.
stdline ! columns.
columns ← [ columns[2], columns[1] ].
taskList setColumns: columns.

stdline ! taskList columns.

class HTMLGenerator : STHTMLGenerator {
}.

stdline ! STHTMLGenerator.
stdline ! HTMLGenerator.

scheme todohtml : MPWMappingStore {
        var taskList.
	/tasks { 
	   get { 
		var table ← self taskList.
                var hs ← HTMLGenerator stream.
                hs html:{ 
                  hs body:{
		    hs ! this:taskList.
                  }.
		}.
                hs target target.
           }
       }
       /tasks1 {
	   get { 
		var table ← self taskList.
                var hs ← MPWByteStream stream.
                hs ! '<html><head></head><body>\n'.
		hs ! '<table>'.
		this:taskList objects do: { :task |
		    hs  writeInterpolatedString:'<tr><td>{title}</td><td><input type=checkbox {checked}></input></td></tr>' withEnvironment: task.
                }.
		hs ! '</table>'.
		hs ! '</body></html>'.
                hs target.
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

todo ← #todohtml{ #taskList: taskList }.
server ← #MPWSchemeHttpServer{ scheme: todo , #port: 8082 }.
server server setThreadPoolSize:1.

scheme:todo := todo.
server start.
stdout println:'number of tasks: ', todo taskList count stringValue.
stdout println:'port: ', server port stringValue.
shell runInteractiveLoop.

