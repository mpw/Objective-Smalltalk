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
		'( title, done ) VALUES (:title,:done)'.
	}
	+sqlForCreateTable {
		'( [id] INTEGER PRIMARY KEY, [title] NVARCHAR(220) NOT NULL, [done] INTEGER );'.
	}
}.


class SQLTable {
	var theClass.
	var db.
	var name.
	-insertSQL {
		theInsert ← this:theClass sqlForInsert.
		"INSERT INTO {this:name}  {theInsert}".
	}
	-<void>insert:array {
		writer ← self db insert: self insertSQL.
		writer writeObject:array.
	}
    -createSQL {
		columnDefs ← this:theClass sqlForCreateTable.
		"CREATE TABLE {this:name}  {columnDefs}".
	}
	-<void>create {
		self db query: self createSQL.
	}
	-objectsForQuery:query {
          builder := MPWObjectBuilder alloc initWithClass: this:theClass.
          self db setBuilder:builder.
          self db query:query.
          result := self db builder result.
		 result.
	}
	-select {
		self objectsForQuery: "select * from {this:name}".
	}
	-selectWhere:query {
		self objectsForQuery: "select * from {this:name} where {query}".
	}
}.


scheme todo : MPWMappingStore {
	var db.
	var tasksTable.
	-initWithRef:ref {
		db := (MPWStreamQLite alloc initWithPath:ref path).
     	self setDb:db.
		taskTable := #SQLTable{ #db: db , #theClass: Task, #name: 'tasks'  }.
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
    		this:tasksTable select.
		}
	}

	/task/:id {
		|= {
			this:tasksTable selectWhere: "id = {id}".
		}
	}
}.
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
