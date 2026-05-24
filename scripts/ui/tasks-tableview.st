#!env stui
framework:ObjectiveHTTPD load.

class Task {
	var id.
	var <bool> done.
	var title.
        -stringId { this:id stringValue. }
	-description { "Task: {this:title} done: {this:done}". }
}

taskList ← #MPWObjectArrayTable[ #Task{ id:0, title: 'Submit paper', done: false }, #Task{ id:1, title: 'Write code', done: true } ].

stdout println: taskList.

tableView ← #MPWTableView{ table: taskList  }.
v ← #VStack{ frame: 400 , views: [ #Label{ text: 'Tasks' },  tableView ] }.
app runFromCLI:(v inScrollView:(200@400 extent: 500@600)).

