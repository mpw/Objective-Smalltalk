#!env stui
#-s3
scheme:s3 ← ref:http://defiant.local:2345/ asScheme
text ← #NSTextField{ #stringValue:'', #frame:(10@45 extent:180@24) }.
text → ref:s3:bucket1/msg.txt.
text.
