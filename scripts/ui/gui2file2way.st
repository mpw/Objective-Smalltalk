#!env stui
#-s3
scheme:tmpf :=  ref:file:/tmp asScheme.
scheme:tmpf setLog: protocol:ModelDidChange. 
field ← #STTextField{ frame:(180@24), binding: ref:tmpf:hello.txt }.
