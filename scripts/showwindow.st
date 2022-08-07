#!env st
framework:ObjectiveSmalltalkUI load.

app := NSApplication sharedApplication.
app setActivationPolicy:0.
text ←  #NSTextField{ #stringValue:'', #frame: (10@45 extent: 180@24) }.
text → MPWPrintLiner → stdout.
button := NSButton buttonWithTitle:'OK' target:app action: 'terminate:'.
button setFrame:(50@10 extent: 100@30).
window := #NSWindow{ #frame: (300@300 extent: 200@105), #title:'Window', #views: #[ text, button] }.
window makeKeyAndOrderFront:nil
app activateIgnoringOtherApps:1.
app run.
