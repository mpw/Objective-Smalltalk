#!env stui
text ←  #NSTextField{ #stringValue:'', #frame: (10@45 extent: 180@24) }.
button ← #NSButton{ #title:'OK', #target:app, #theAction:'terminate:', #frame: (50@10 extent: 100@30) }.
window ← #NSWindow{ #frame: (300@300 extent: 200@105), #title:'Window', #views: #[ text, button] }.
text → MPWPrintLiner → stdout.
app runFromCLI:window.
