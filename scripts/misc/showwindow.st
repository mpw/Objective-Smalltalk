#!env stui
text ← #NSTextField{ #stringValue:'', #frame:(10@45 extent:180@24) }.
window ← #NSWindow{ #frame:(300@300 extent:200@105),#title:'Enter Text', #views:#[text]}.
text → MPWPrintLiner → stdout.
app runFromCLI:window.
