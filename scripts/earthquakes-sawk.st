#!env st
#-<void>sawk:<ref>file
file  csv: { :time :latitude :longitude :depth :magnitude |
	stdout println:"Magnitude: {magnitude} location: {latitude},{longitude} time: {time}".
}.
