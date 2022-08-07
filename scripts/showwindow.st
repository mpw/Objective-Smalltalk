#!env st
framework:AppKit load.
framework:MPWFoundationUI load.

class Target { 
  var text.
  -<void>showText:sender {
     stdout println:self text stringValue.
     NSApplication sharedApplication terminate:nil.
  }
}.

app := NSApplication sharedApplication.
app setActivationPolicy:0.
t := Target new.
text := NSTextField textFieldWithString:''.
text setFrame:(10@45 extent: 180@24).
t setText:text.
button := NSButton buttonWithTitle:'OK' target:t action: 'showText:'.
button setFrame:(50@10 extent: 100@30).
window := #NSWindow{ #frame: (300@300 extent: 200@105), #title:'Window', #views: #[ text, button] }.
window makeKeyAndOrderFront:nil
app activateIgnoringOtherApps:1.
app run.
