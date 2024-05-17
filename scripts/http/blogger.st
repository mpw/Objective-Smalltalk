#!env st
#-<void>blogger:accessToken
scheme:https setAccessToken:accessToken.
blogid ← '8397311766319215218'.
theRef ← ref:https://www.googleapis.com/blogger/v3/blogs/{blogid}/ 
stdout println: theRef.
scheme:blogger ← theRef asScheme
stdout println:'blogger:posts'
shell runInteractiveLoop.
