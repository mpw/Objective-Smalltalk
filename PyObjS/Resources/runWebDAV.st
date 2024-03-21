#!env st
framework:PyObjS load
py := STPython new.
py loadSchemeWebDAV.
py runWebDAV: scheme:env port:8081.
