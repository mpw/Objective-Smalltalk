#!env stsh
framework:ObjectiveHTTPD load.

class Task {
	var id.
	var <bool> done.
	var title.
	-description { "Task: {this:title} done: {this:done}". }
	-<void>writeOnJSONStream:aStream {
		aStream writeDictionaryLikeObject:self withContentBlock:{ :writer |
			writer writeInteger: this:id forKey:'id'.
			writer writeString: this:title forKey:'title'.
			writer writeInteger: this:done forKey:'done'.
		}.
	}
}

taskList ← #( #Task{ #id: '1', #title: 'Clean Room', #done: false }, #Task{ #id: '2', #title: 'Check Twitter', #done: true } ).

scheme todo {
	var taskDict.
	var store.
	-schemeNames {  #( 'store' ). }
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
		store:tasks := this:taskDict allValues.
	}
}.

persistenceJSON := #MPWJSONConverterStore{ #toJSONUp: false, #class: class:Task }.
persistenceFile := ref:file:/tmp/tasks/ asScheme.
persistence := persistenceJSON → persistenceFile.
todo := #todo{ #taskList: taskList, #store: persistence }.
json := #MPWJSONConverterStore{  #toJSONUp: true, #class: class:Task }.
json → todo.
server := #MPWSchemeHttpServer{ #scheme: json, #port: 8082 }.
server start.
shell runInteractiveLoop.

