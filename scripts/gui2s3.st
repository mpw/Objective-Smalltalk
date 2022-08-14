#!env stui
scheme:s3 ← ref:http://localhost:10001/ asScheme
text ← #NSTextField{ #stringValue:'', #frame:(10@45 extent:180@24) }.
window ← #NSWindow{ #frame:(300@300 extent:200@105),#title:'S3', #views:#[text]}.
text → ref:s3:bucket1/message.txt.
app runFromCLI:window.
