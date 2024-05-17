#!env stui
#-<void>gezira
framework:Gezira load.
demo := StrokeDemo new.
view := #NSImageView{ frame: (400@400) }.
window := view openInWindow:'Gezira'.
demo run:view.
shell runInteractiveLoop.
