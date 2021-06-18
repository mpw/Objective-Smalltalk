#!env stsh
#-sawk:<ref>file
file  awk: { :time :latitude :longitude :depth :magnitude |
	stdout println:"Magnitude: {magnitude} location: {latitude},{longitude} time: {time}".
}.
