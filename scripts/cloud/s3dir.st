#!env st
#-ls
dir := args count > 0 ifTrue:{ args lastObject.} ifFalse:{ '.'. }.
scheme:s3 := ref:http://localhost:10001/ asScheme
buckets := (MPWMAXParser parser process: s3:{dir})['Contents'].
buckets collect at:'Key' 
