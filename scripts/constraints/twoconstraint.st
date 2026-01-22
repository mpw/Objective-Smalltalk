#!env st
scheme:l := MPWLoggingStore storeWithSource: MPWDictStore store.
scheme:default := scheme:l.
a ← 3. b ← 5. c ← 10.
c |= b.
a |= b.
a.
b.
b := 52
var:stdout println:a.
var:stdout println:c.
