#!env stsh
#-hardtask:<ref>dbref
#
framework:ObjectiveHTTPD load.


class Task {
	var <int> id.
	var <bool> done.
	var <NSString> title.
	-description { "<Task: title: {this:title} done: {this:done}>". }
	+sqlInsertKeys {
		#( 'title', 'done' ).
	}
	+sqlForCreate {
		'( [id] INTEGER PRIMARY KEY, [title] NVARCHAR(220) NOT NULL, [done] INTEGER );'.
	}
}.

stdout println:'top'.

scheme todo : MPWAbstractStore {
	var db.
	var tasksTable.
	-initWithRef:ref {
		this:db := (MPWStreamQLite alloc initWithPath:ref path).
		this:tasksTable :=  #MPWSQLTable{ #db: this:db , #tableClass: Task, #name: 'tasks'  }.
		this:db open.
		self.
	}
	-<void>createTable {
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
