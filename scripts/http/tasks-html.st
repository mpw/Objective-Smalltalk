#!env st
framework:ObjectiveHTTPD load.

class Task {
	var id.
	var <bool> done.
	var title.
        -stringId { this:id stringValue. }
	-description { "Task: {this:title} done: {this:done}". }
        -checked {  this:done ifTrue:'checked' ifFalse:''. }
}

taskList ← #MPWObjectArrayTable[ #Task{ id:0, title: 'Submit paper', done: false }, #Task{ id:1, title: 'Write code', done: true } ].

stdout println: taskList.

scheme todohtml : MPWMappingStore {
        var taskList.
	/tasks { 
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

scheme:todo := todo.
server start.
stdout println:'number of tasks: ', todo taskList count stringValue.
stdout println:'port: ', server port stringValue.
shell runInteractiveLoop.

