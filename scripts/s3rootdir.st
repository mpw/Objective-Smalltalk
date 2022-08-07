#!env st
#-ls
scheme:s3 := ref:http://localhost:10001/ asScheme
buckets := MPWMAXParser parser process: s3:. 
buckets := buckets at:'Buckets' 
buckets := buckets objectsForKey:'Bucket'
buckets collect objectForKey:'Name'
