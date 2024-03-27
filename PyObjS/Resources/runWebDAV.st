#!env st
framework:PyObjS load
py := STPython new.
py loadSchemeWebDAV.
largerDict ← #MPWDictStore{ a: 1, b: 2, c: 3 , d: 4, e: 5 , f: 6, g: 7, h: 8 }.
smallDict ← #MPWDictStore{ a: 1, b: 2 }
#py runWebDAV: scheme:defaults port:8080 at:'defaults'
py runWebDAV: ref:file:/Users/marcel/ asScheme port:8081 at:'tmp-mount1'
#py runWebDAV: smallDict  port:8082 at:'dict'
#py runWebDAV: scheme:env port:8083 at:'env'
