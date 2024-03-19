#!env st
framework:PyObjS load
py := STPython new.
py loadSchemeWebDAV.
stdout println: py mainModule asObject.
py runWebDAV: scheme:defaults port:8081.
