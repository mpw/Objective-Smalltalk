#!env stsh
#-sawk:<ref>file
block := { :time :latitude :longitude :depth :magnitude |
    stdout println:"Magnitude: {magnitude} location: {latitude},{longitude} time: {time}".
}
awk ← STAWK stream.
awk setBlock:block.
awk setSeparator:','.
stdout println:awk.
lines := file lines.
lines setFinalTarget:awk.
lines run.
