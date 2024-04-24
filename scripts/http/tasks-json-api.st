#!env stsh
framework:ObjectiveHTTPD load.

class Task {
	var id.
	var <bool> done.
	var title.
        -stringId { this:id stringValue. }
	-description { "Task: {this:title} done: {this:done}". }
}

taskList ← #( #Task{ id:0, title: 'Clean Room', done: false }, #Task{ id:1, title: 'Check Twitter', done: true } ).

scheme todo : MPWMappingStore {
	var taskDict.
        -taskList {
           this:taskDict allValues.
        }
	-<void>setNewTaskList:aList {
		this:taskDict := aList mutableDictionaryByKey:'stringId'.
	}
	/tasks { 
	   get { 
			self taskList.
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

todo ← #todo{ #newTaskList: taskList }.
json ← #MPWJSONConverterStore{  #up: true, #converterClass: class:Task }.
json → todo → #MPWJSONConverterStore{  #converterClass: class:Task } → ref:file:/tmp/tasks/ asScheme.
server ← #MPWSchemeHttpServer{ #scheme: json, #port: 8082 }.
scheme:todo := todo.
server start.
stdout println:'number of tasks: ', todo taskList count stringValue.
stdout println:'port: ', server port stringValue.
shell runInteractiveLoop.

