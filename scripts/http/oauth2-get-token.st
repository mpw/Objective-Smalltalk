#!env st
#-<void>oauth-get-token
framework:ObjectiveHTTPD load.
scheme:https setHeaders: #{ Content-Type: 'application/json' }.

code ← '4/0AdLIrYeDHx5JBJQ_tZCPfrZv2J-CuUKGMQKnS0sHaT18k3JK7BjRMGdDPMMji95tI6Zqcw'.
id ← '947980164489-2g6brn5f4ksrlgb8qvmhjfc3v0e9lki4.apps.googleusercontent.com'.
redirect ← 'com.googleusercontent.apps.947980164489-2g6brn5f4ksrlgb8qvmhjfc3v0e9lki4:/oauth2callback'
grant ← 'authorization_code'.

requestDict ← NSMutableDictionary dictionary.
requestDict setObject:code forKey:'code'.
requestDict setObject:id forKey:'client_id'.
requestDict setObject:grant forKey:'grant_type'.
requestDict setObject:redirect forKey:'redirect_uri'.
requestDict setObject:'' forKey:'scope'.
stdout println: 'request dict: '.
stdout println: requestDict 
stdout println: 'JSON request dict: '.
stdout println: requestDict asJSON

tokenRef := ref:https://oauth2.googleapis.com/token 

response ← tokenRef post: requestDict asJSON.

stdout println: 'response: '.
stdout println: response.
scheme:https atURL:(NSURL URLWithString:'https://oauth2.googleapis.com/token') postDictionary: requestDict.

response ← tokenRef post: requestDict asJSON.

stdout println: 'response: '.
stdout println: response.
