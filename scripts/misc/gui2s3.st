#!env stui
#-s3
scheme:s3 ← ref:http://localhost:10001/ asScheme

text ← #NSTextField{ #frame:(180@24) }.

text → ref:s3:bucket1/message.txt.
