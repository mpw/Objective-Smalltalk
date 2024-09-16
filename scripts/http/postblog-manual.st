#!env st
#-<void>post:title text: <ref>body
scheme:https setHeaders: #{ Content-Type: 'application/json' }.
scheme:https setAccessToken:  keychain:password/blogger.com/access_token stringValue.
blogid ← '8397311766319215218'.
theRef ← ref:https://www.googleapis.com/blogger/v3/blogs/{blogid}/ 
scheme:blogger ← theRef asScheme
postDict := #{ kind: 'blogger#post', blog: #{ id: blogid }, title: title, content: body value stringValue  }.
postResponse := ref:blogger:posts/ post: postDict asJSON.
stdout println:postResponse.
