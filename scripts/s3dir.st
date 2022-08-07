#!env st
#-ls
scheme:s3 := ref:http://localhost:10001/ asScheme
buckets := MPWMAXParser plistParser process: s3:. | at:'Buckets'
buckets collect at:'Name'
