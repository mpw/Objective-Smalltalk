#!env stsh
#-hardtask:<ref>dbref
#
framework:ObjectiveHTTPD load.

class Task {
	var <bool> done.
	var title.
	-description { "Task: {this:title} done: {this:done}". }
	+sqlForInsert {
		'INSERT INTO tasks ( title, done ) VALUES (:title,:done)'.
	}
}


scheme todo : MPWMappingStore {
	var db.
	-initWithRef:ref {
     	self setDb:(MPWStreamQLite alloc initWithPath:ref path).
	}
	var taskDict.
	-tableCreationSQL {
		'CREATE TABLE tasks ( [title] NVARCHAR(220) NOT NULL, [done] INTEGER );'.
	}
	-<void>createTable {
		self db open.
		stdout println: this:db.
		self db query: self tableCreationSQL.
	}
	-<void>insertTasks {
		self db open.
		taskList ← #( #Task{  #title: 'Clean Room', #done: false }, #Task{  #title: 'Check Twitter', #done: true } ).
		writer ← self db insert: (taskList at:0 ) class sqlForInsert.
		writer beginArray.
		taskList do: { :task | 
			task writeOnJSONStream:writer.
		}.
		writer endArray.
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
todo createTable.


todo insertTasks.
shell runInteractiveLoop.
