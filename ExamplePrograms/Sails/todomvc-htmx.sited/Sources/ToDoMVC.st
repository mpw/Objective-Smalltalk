scheme ToDoMVC  {
  var bundle.
  var count.
  -init {
     self ← super init.
     this:count ← 0.
     stdout println: self description.
     self.
  }
  /htmx { get {  this:bundle resources at:'htmx.js'. } }
  /{ get { this:bundle resources at:'clickme.htmx'.  } }
  /clicked { get { 
      stdout println:'clicked'.
      stdout println: this:count stringValue.
      this:count ← this:count + 1. "Clicked count: {this:count}".   } }
}
