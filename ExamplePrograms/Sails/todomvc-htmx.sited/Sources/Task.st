class Task {
        var id.
        var <bool> done.
        var title.
        var <Date> dueDate.
        -stringId { this:id stringValue. }
        -description { "Task: {this:title} done: {this:done}". }
        -checked {  this:done ifTrue:'checked' ifFalse:''. }
}
