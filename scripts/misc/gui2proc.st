#!env stui
#-text

text ← #NSTextField{ #frame:(180@24) }.

text → { :hi | stdout println:hi. }.
