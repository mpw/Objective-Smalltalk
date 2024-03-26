#!env st
framework:PyObjS load
py := STPython new.
py loadSchemeWebDAV.
#py runWebDAV: scheme:defaults port:8080 at:'defaults'
py runWebDAV: ref:file:/tmp/ asScheme port:8081 at:'tmp-remount'
#py runWebDAV: #MPWDictStore{ a: 2, b:3 }  port:8082 at:'dict'
#py runWebDAV: scheme:env port:8083 at:'env'
