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
	+sqlForCreateTable {
		'CREATE TABLE tasks ( [id] INTEGER PRIMARY KEY, [title] NVARCHAR(220) NOT NULL, [done] INTEGER );'.
	}
}.


class SQLTable {
	var theClass.
	var db.
	-<void>insert:array {
		writer ← self db insert: this:theClass sqlForInsert.
		writer writeObject:array.
	}
	-<void>create {
		self db query: this:theClass sqlForCreateTable.
	}
	-objectsForQuery:query {
          builder := MPWObjectBuilder alloc initWithClass: this:theClass.
          self db setBuilder:builder.
          self db query:query.
          result := self db builder result.
		 result.
	}
}.


scheme todo : MPWMappingStore {
	var db.
	var tasksTable.
	-initWithRef:ref {
		db := (MPWStreamQLite alloc initWithPath:ref path).
     	self setDb:db.
		taskTable := #SQLTable{ #db: db , #theClass: Task  }.
		self setTasksTable:taskTable.
		self.
	}
	-<void>createTable {
		self db open.
		this:tasksTable create.
	}
	-<void>insertTasks {
		taskList ← #( #Task{  #title: 'Clean Room', #done: false }, #Task{  #title: 'Check Twitter', #done: true } ).
		this:tasksTable insert:taskList.
	}
	/tasks { 
		|= { 
    		this:tasksTable objectsForQuery: 'select * from tasks'.  
		}
	}

	/task/:id {
		|= {
			this:tasksTable objectsForQuery: "select * from tasks where id = {id}".
		}
	}
}.
stdout println:'start'.
MPWSQLiteWriter stream createEncoderMethodForClass: Task.
todo := todo alloc initWithRef:dbref.
json := #MPWJSONConverterStore{  #up: true, #converterClass: class:Task }.
json → todo.
scheme:todo ← todo.
server := #MPWSchemeHttpServer{ #scheme: json, #port: 8082 }.
server start.
stdout println:'port: ', server port stringValue.
todo createTable.
todo insertTasks.
shell runInteractiveLoop.
