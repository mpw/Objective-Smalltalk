#!env stui

#!env st
#-<void>blogger
scheme:https setAccessToken: keychain:password/blogger.com/access_token stringValue.
#scheme:https setAccessToken:  env:TOKEN.
blogid ← '8397311766319215218'.
theRef ← ref:https://www.googleapis.com/blogger/v3/blogs/{blogid}/ 
scheme:blogger ← theRef asScheme
a := (scheme:blogger at:'posts/?fields=kind%2Citems(title%2Cid)' ) at:'items'
table ← #MPWTableView{items:(a)}.
app runFromCLI:(table inScrollView:(200@400 extent: 500@600)).
