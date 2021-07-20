#!env stsh
#-taskbench:<ref>dbref
#

class Task {
	var <int> id.
	var <bool> done.
	var <NSString> title.
	-description { "<Task: title: {this:title} done: {this:done}>". }
	+sqlForCreate {
		'( [id] INTEGER PRIMARY KEY, [title] VARCHAR(220) NOT NULL, [done] INTEGER );'.
	}
}.

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
	    this:tasksTable := this:db tables at:'tasks'.
	}
	-createTaskListToInsert:<int>log10ofSize {
		baseList ← #( #Task{  #title: 'Clean Room', #done: false }, #Task{  #title: 'Check Twitter', #done: true } ).
	    taskList ← NSMutableArray array.	
		1 to:5 do: {
			taskList addObjectsFromArray: baseList.	
		}.
		1 to: log10ofSize - 1 do: { 
			nextTen := NSMutableArray array.
			1 to: 10 do: {
	            nextTen addObjectsFromArray: taskList.
			}.
			taskList := nextTen.
		}.
		taskList.
	}
	-<void>insertTasks {
	    taskList := self createTaskListToInsert:6.
		stdout println: taskList count.
		1 to:10 do: {
			this:tasksTable insert:taskList.
		}.
	}
}.
MPWSQLTable stream createEncoderMethodForClass: Task.
todo := todo alloc initWithRef:dbref.
todo createTable.
todo db enableWAL.
todo db query:'PRAGMA journal_mode = OFF;'.
todo db query:'PRAGMA synchronous = 0;'.
todo db query:'PRAGMA cache_size = 1000000;;'
todo db query:'PRAGMA locking_mode = EXCLUSIVE;'.
todo db query:'PRAGMA temp_store = MEMORY;'.
todo insertTasks.
