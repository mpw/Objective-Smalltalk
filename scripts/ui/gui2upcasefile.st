#!env stui
#-s3
text ← #NSTextField{ frame:(180@24) }.
filter Upcase |{ ^object uppercaseString. }.
text → (#Upcase{} → ref:file:/tmp/hello.txt ).
