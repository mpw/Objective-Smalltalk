#!env st
framework:AppKit load.

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
window := NSWindow alloc initWithContentRect: (300@300 extent: 200@85) styleMask: 1 backing:2 defer:0.
window setTitle:'A Window'.
window makeKeyAndOrderFront:nil.
text := NSTextField textFieldWithString:''.
text setFrame:(10@45 extent: 180@24).
window contentView addSubview:text.
t setText:text.
button := NSButton buttonWithTitle:'OK' target:t action: 'showText:'.
button setFrame:(50@10 extent: 100@30).
window contentView addSubview:button.
app activateIgnoringOtherApps:1.
app run.
