#!env stsh
#-sawk:<ref>file
file awk: { :time :longitude :latitude :dummy :magnitude |
	stdout println:"Magnitude: {magnitude} location: {latitude},{longitude} time: {time}".
}.
