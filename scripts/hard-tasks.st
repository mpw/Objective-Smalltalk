#!env stsh

class Task {
	var <bool> done.
	var title.
}

scheme todo {

/tasks {
   |= { 
		#( #Task{ #done: false, #title: 'Clean Room' } , #Task{ #done: true, #title: 'Check Twitter' } ).
	}
}
}.

scheme:todo := todo new.
shell runInteractiveLoop.
