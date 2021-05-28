#!env stsh
framework:ObjectiveHTTPD load.

class Task {
	var <bool> done.
	var title.
	-description { "Task: {this:title} done: {this:done}". }
	-<void>writeOnJSONStream:aStream {
		aStream writeDictionaryLikeObject:self withContentBlock:{ :writer |
			writer writeString: this:title forKey:'title'.
			writer writeInteger: this:done forKey:'done'.
		}.
	}
}

taskList ← #( #Task{ #title: 'Clean Room', #done: false }, #Task{ #title: 'Check Twitter', #done: true } ).

scheme todo {
	var taskList.
	/tasks { 
		|= { 
			this:taskList.
		}
	}
}.

todo := #todo{ #taskList: taskList }.
json := #MPWJSONConverterStore{  #toJSONUp: true, #class: class:Task }.
json → todo.
server := #MPWSchemeHttpServer{ #scheme: json, #port: 8082 }.
server start.
shell runInteractiveLoop.

