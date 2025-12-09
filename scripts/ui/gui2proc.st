#!env stui
#-tex
NSProcessInfo processInfo setProcessName:'gui2proc'.
text ← #NSTextField{ frame:(180@24) }.

text → { stdout println:$0. }.
