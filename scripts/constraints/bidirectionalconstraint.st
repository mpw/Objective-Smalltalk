#!env st
scheme:l := MPWLoggingStore storeWithSource: MPWDictStore store.
scheme:default := scheme:l.
a ← 3. b ← 5.
constraints ← (a =|= b).
stdout println: constraints.
a.
b.
b := 52
var:stdout println:a.
a := 4.
var:stdout println:b.
