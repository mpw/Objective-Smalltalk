#!env stui
framework:ObjectiveHTTPD load.

class Task {
	var <bool> done.
	var title.
	-description { "Task: {this:title} done: {this:done}". }
}


scheme TaskSite  {
    var taskList.
    /newTask {
       put {
         stdout println:'new Task'. 
         stdout println:'new Task, title: ', newValue. 
         var task ←  #Task{ title: (newValue, ' - newTask' ) }.
         stdout println:'new Task: ',task.
         this:taskList insertObject: task  atIndex:0. 
         stdout println: this:taskList.
         protocol:ModelDidChange notify.
         }
      }


}

taskList ← #MPWObjectArrayTable[ #Task{  title: 'Submit paper', done: false }, #Task{  title: 'Write code', done: true } ].

scheme:site ← #TaskSite{ taskList: taskList }.

tableView ← #MPWTableView{ table: taskList  }.
tableView reloadData.
taskInput ← #STTextField{ } 
taskInput → ref:site:/newTask.
v ← #VStack{ frame: 400 , views: [ #Label{ text:'New Task'} , taskInput ,(tableView  inScrollView:(200@400 extent: 500@600)) ] }.
app runFromCLI:v.
taskList.
