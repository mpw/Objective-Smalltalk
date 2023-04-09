#!env stsh
framework:ObjectiveHTTPD load.

class Task {
	var id.
	var <bool> done.
	var title.

	-description { "Task: {this:title} done: {this:done}". }
}

taskList ← #( #Task{ #id: 1, #title: 'Clean Room', #done: false }, #Task{ #id: 2, #title: 'Check Twitter', #done: true } ).

scheme todo : MPWMappingStore {
	var taskDict.
	var taskList.
	-<void>setNewTaskList:aList {
		d := NSMutableDictionary dictionary.
		i := 0.
		aList do: { :task |
			task setId:i.  i := i+1.
			d[task id stringValue] := task.
		}.
		this:taskDict := d.
		this:taskList := aList.
		stdout println: this:taskDict.
	}
	/tasks { 
		|= { 
			this:taskList.
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
		source:tasks := this:taskList.
	}
}.

todo := #todo{ #newTaskList: taskList }.
json := #MPWJSONConverterStore{  #up: true, #converterClass: class:Task }.
json → todo → #MPWJSONConverterStore{  #converterClass: class:Task } → ref:file:/tmp/tasks/ asScheme.
server := #MPWSchemeHttpServer{ #scheme: json, #port: 8082 }.
server start.
stdout println:'number of tasks: ', todo taskList count stringValue.
stdout println:'port: ', server port stringValue.
shell runInteractiveLoop.

