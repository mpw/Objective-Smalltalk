#!env stui
#-field
text ← #NSTextField{ #frame: (180@24)  }.
text → port:stdout/println: .
