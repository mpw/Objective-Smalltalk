#!env st
#-<void>post:<ref>blogbundle id:<int>postId
framework:BlogBuilding load.
bundle ← STBundle alloc initWithPath: blogbundle path.

scheme:https setHeaders: #{ Content-Type: 'application/json' }.
scheme:https setAccessToken: env:TOKEN .
blogid ← '8397311766319215218'.
theRef ← ref:https://www.googleapis.com/blogger/v3/blogs/{blogid}/ 
scheme:blogger ← theRef asScheme
postDict := #{ kind: 'blogger#post', blog: #{ id: blogid }, title: title, content: body value stringValue  }.
#postResponse := ref:blogger:posts/ post: postDict asJSON.
stdout println:postResponse.
