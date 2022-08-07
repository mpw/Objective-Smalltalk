#!env st
#-ls
dir := args count > 0 ifTrue:{ args lastObject.} ifFalse:{ '.'. }.
scheme:s3 := ref:http://localhost:10001/ asScheme
parser := MPWMAXParser parser .
parser setUndefinedTagAction:2.
buckets := parser process: s3:{dir}  | objectsForKey:'Contents'.
buckets collect at:'Key' 