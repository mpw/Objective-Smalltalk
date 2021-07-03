#!env stsh
#-hardtask:<ref>dbref
#
framework:ObjectiveHTTPD load.

class Task {
	var <int> id.
	var <bool> done.
	var <NSString> title.
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
	-tableCreationSQL {
		'CREATE TABLE tasks ( [id] INTEGER PRIMARY KEY, [title] NVARCHAR(220) NOT NULL, [done] INTEGER );'.
	}
	-<void>createTable {
		self db open.
		self db query: self tableCreationSQL.
	}
	-<void>insertTasks {
		taskList ← #( #Task{  #title: 'Clean Room', #done: false }, #Task{  #title: 'Check Twitter', #done: true } ).
		writer ← self db insert: this:taskClass sqlForInsert.
		writer writeObject:taskList.
	}
	  -objectsForQuery:query  {
          builder := MPWObjectBuilder alloc initWithClass: this:taskClass.
          self db setBuilder:builder.
          self db query:query.
          result := self db builder result.
		 result.
  }
	/tasks { 
		|= { 
    		self objectsForQuery: 'select * from tasks'.  
		}
	}

	/task/:id {
		|= {
			self objectsForQuery: "select * from tasks where id = {id}".
		}
	}
}.
MPWSQLiteWriter stream createEncoderMethodForClass: Task.
todo := #todo{  #db: ( MPWStreamQLite open:dbref path), #taskClass: Task  }.
json := #MPWJSONConverterStore{  #up: true, #converterClass: class:Task }.
json → todo.
scheme:todo ← todo.
server := #MPWSchemeHttpServer{ #scheme: json, #port: 8082 }.
server start.
stdout println:'port: ', server port stringValue.
todo createTable.
todo insertTasks.
shell runInteractiveLoop.
