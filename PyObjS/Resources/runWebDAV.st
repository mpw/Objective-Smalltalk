#!env st
framework:PyObjS load
py := STPython new.
py loadSchemeWebDAV.
py mainModule at:'runServer' | call:nil.
