#!env st
#-<void>blogger
scheme:https setHeaders: #{ Content-Type: 'application/json' }.
scheme:https setAccessToken: keychain:password/blogger.com/access_token stringValue.
blogid ← '8397311766319215218'.
theRef ← ref:https://www.googleapis.com/blogger/v3/blogs/{blogid}/ 
scheme:blogger ← theRef asScheme
shell runInteractiveLoop.
