#!env st
framework:PyObjS load
py := STPython new.
py loadSchemeWebDAV.
#py runWebDAV: scheme:env port:8081.
py runWebDAV: ref:file:/tmp/ asScheme port:8081.
#py runWebDAV: #MPWDictStore{ a: 2, b:3 }  port:8081.
