#!env st
scheme:l := MPWLoggingStore storeWithSource: MPWDictStore store.
scheme:default := scheme:l.
a ← 3. b ← 5.
a |= b
a
b
b := 52
var:stdout println:a.
