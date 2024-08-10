#!env st
#-<void>oauth
framework:ObjectiveHTTPD load.

rtoken ← keychain:password/blogger.com/refresh_token stringValue.
scope ← 'https%3A//www.googleapis.com/auth/blogger'.
id ← keychain:password/blogger.com/client_id stringValue.


dict ← #{ grant_type: 'refresh_token', refresh_token: rtoken, client_id: id }.
uri ← ref:https://oauth2.googleapis.com/token'.
result ← scheme:https at: uri post:dict.
stdout println: 'Access token before: ', result["access_token"].
keychain:password/blogger.com/access_token ← result["access_token"].
stdout println: result.
stdout println: 'Access token after: ', result["access_token"].

