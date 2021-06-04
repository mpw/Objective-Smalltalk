#!env stsh
framework:ObjectiveHTTPD load.

class Task {
	var id.
	var <bool> done.
	var title.
	-description { "Task: {this:title} done: {this:done}". }
}

taskList ← #( #Task{ #id: '1', #title: 'Clean Room', #done: false }, #Task{ #id: '2', #title: 'Check Twitter', #done: true } ).

scheme todo : MPWMappingStore {
	var taskDict.
	-<void>setTaskList:aList {
		this:taskDict := NSMutableDictionary dictionaryWithObjects: aList forKeys: aList collect id.
		stdout println: this:taskDict.
	}
	/tasks { 
		|= { 
			this:taskDict allValues.
		}
	}
	/task/:id {
		|= {
			this:taskDict at:id .
		}
		=| {
			this:taskDict at:id put:newValue.
			self persist.
		}
	}
	-<void>persist {
		source:tasks := this:taskDict allValues.
	}
}.

todo := #todo{ #taskList: taskList }.
json := #MPWJSONConverterStore{  #up: true, #class: class:Task }.
json → todo → #MPWJSONConverterStore{  #class: class:Task } → ref:file:/tmp/tasks/ asScheme.
server := #MPWSchemeHttpServer{ #scheme: json, #port: 8082 }.
server start.
shell runInteractiveLoop.

