#!env st
metal := framework:metal
metal load.
initfun ← metal functionNamed:'MTLCreateSystemDefaultDevice'
defaultdevice ← initfun value.
stdout println:defaultdevice.
