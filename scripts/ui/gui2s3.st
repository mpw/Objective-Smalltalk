#!env stui
#-s3
#  local simulator is 'minio', needs to be configured using its
#  web UI to allow anonymous access to the bucket, so can't
#  just put files and serve them.
#  experiment more with authentication

scheme:s3 ← ref:http://localhost:9000/ asScheme
scheme:s3 source setHeaders: #{ user: 'minioadmin' , password: 'minioadmin' }.
text ← #NSTextField{ frame:(180@24) }.

text → ref:s3:bucket1/message.txt.
