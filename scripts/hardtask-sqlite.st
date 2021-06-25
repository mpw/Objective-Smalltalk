#!env stsh
#-hardtask:<ref>dbref
#
framework:ObjectiveHTTPD load.

class Task {
	var <bool> done.
	var title.
	-description { "<Task: title: {this:title} done: {this:done}>". }
	+sqlForInsert {
		'INSERT INTO tasks ( title, done ) VALUES (:title,:done)'.
	}
}


scheme todo : MPWMappingStore {
	var db.
	var taskClass.
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
	  -objectsForQuery:query  {
          builder := MPWObjectBuilder alloc initWithClass: this:taskClass.
          self db setBuilder:builder.
          self db query:query.
          result := self db builder result.
         stdout println:result.
		 result.
  }
	/tasks { 
		|= { 
    		self objectsForQuery: 'select * from tasks' class: Task.  
		}
	}

	/task/:id {
		|= {
			self objectsForQuery: "select * from tasks where rowid = {id}".
		}
		=| {
			this:taskDict at:id put:newValue.
		}
	}
}.

todo := #todo{  #db: ( MPWStreamQLite alloc initWithPath:dbref path), #taskClass: Task  }.
json := #MPWJSONConverterStore{  #up: true, #converterClass: class:Task }.
json → todo.
scheme:todo ← todo.
server := #MPWSchemeHttpServer{ #scheme: json, #port: 8082 }.
server start.
stdout println:'port: ', server port stringValue.
todo createTable.
todo insertTasks.
shell runInteractiveLoop.
