#!env stsh
#-<void>taskbench:<ref>dbref
#

class Task {
	var <int> id.
	var <bool> done.
	var <NSString> title.
	-description { "<Task: title: {this:title} done: {this:done}>". }
}.

scheme todo : MPWAbstractStore {
	
	var tasksTable.
	-initWithRef:ref {
		self.
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
	    taskList := self createTaskListToInsert:8.
		stdout println: taskList count.
		1 to:1 do: {
			writer := MPWJSONWriter streamWithTarget:(MPWByteStream fileName:'/tmp/json').
			writer writeObject:taskList.
			writer close.
		}.
	}
}.
MPWJSONWriter stream createEncoderMethodForClass: Task.
todo := todo alloc initWithRef:dbref.
todo insertTasks.
