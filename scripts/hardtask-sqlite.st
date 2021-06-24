#!env stsh
#-hardtask:<ref>dbref
#
framework:ObjectiveHTTPD load.

class Task {
	var id.
	var <bool> done.
	var title.
	-description { "Task: {this:title} done: {this:done}". }
	-sql {
		"INSERT INTO tasks ( Title Completed ) VALUES ( '{this:title}' '{this:done}'; ".
	}
}


scheme todo : MPWMappingStore {
	var db.
	-initWithRef:ref {
     	self setDb:(MPWStreamQLite alloc initWithPath:ref path).
	}
	var taskDict.
	-tableCreationSQL {
		'CREATE TABLE tasks ( [Title] NVARCHAR(220) NOT NULL, [Completed] INTEGER );'.
	}
	-<void>createTable {
		self db open.
		stdout println: this:db.
		self db query: self tableCreationSQL.
	}
	-<void>insertTasks {
		self db open.
		taskList ← #( #Task{ #id: '1', #title: 'Clean Room', #done: false }, #Task{ #id: '2', #title: 'Check Twitter', #done: true } ).
		writer ← self db insert:'INSERT INTO Tasks ( Title, Completed ) VALUES (:a,:b )'.
		writer beginArray.
		taskList do: { :task | 
			writer beginDictionary.
			writer writeObject: task title forKey:'a'.
			writer writeInteger: task done intValue forKey:'b'.
			writer endDictionary.
		}.
		writer endArray.
	}
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

todo := #todo{  #db: ( MPWStreamQLite alloc initWithPath:dbref path)  }.
json := #MPWJSONConverterStore{  #up: true, #converterClass: class:Task }.
json → todo → #MPWJSONConverterStore{  #converterClass: class:Task } → ref:file:/tmp/tasks/ asScheme.
server := #MPWSchemeHttpServer{ #scheme: json, #port: 8082 }.
server start.
shell runInteractiveLoop.
