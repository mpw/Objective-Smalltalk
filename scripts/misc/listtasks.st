#!env stsh
#-<void>listTasks:<ref>dirRef

scheme TodoJSON : MPWJSONConverterStore {
    -entityName { this:converterClass entityName. }
    -mapReference:ref {
        self referenceForPath:"{this:entityName}-{var:ref/path}.json".
    }
}.

class ToDoBase {
  var id.
  var title.
  +entityName { self className lowercaseString. }
}.

class Task : ToDoBase { 
   var completed_at.
   -description { "<Task: title: {this:title} id: {this:id} done: {this:done}>". }
   -<boolean>done { this:completed_at length isNotNil. }
}.
class List : ToDoBase { 
   -description { "<List: title: {this:title} id: {this:id}". }
   -tasksRef { ref:tasks:{this:id}  }
   -tasks { this:tasksRef value.  }
}.

dir ← dirRef asScheme. 
scheme:tasks ← #TodoJSON{ #converterClass: Task } → dir.
scheme:lists ← #TodoJSON{ #converterClass: List } → dir.


lists:2 do: { :list | 
   stdout println: list title.
   stdout do println: list tasksRef value each.
}.
