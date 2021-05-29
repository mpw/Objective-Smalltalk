#!env stsh
framework:ObjectiveHTTPD load.

class Task {
	var <int>  id.
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

taskList ← #( #Task{ #id: 1, #title: 'Clean Room', #done: false }, #Task{ #id: 2, #title: 'Check Twitter', #done: true } ).

scheme todo {
	var taskList.
	/tasks { 
		|= { 
			this:taskList.
		}
	}
	/task/:id {
		|= {
            id ← id intValue.
			matches := this:taskList select:{ :aTask | aTask id = id. }.
			matches firstObject.
		}
	}
}.

todo := #todo{ #taskList: taskList }.
json := #MPWJSONConverterStore{  #toJSONUp: true, #class: class:Task }.
json → todo.
server := #MPWSchemeHttpServer{ #scheme: json, #port: 8082 }.
server start.
shell runInteractiveLoop.

