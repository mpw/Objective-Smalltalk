#!env stsh
stream ← ref:https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv linesAfter:1.
stream do: { :theLine |
    values ← theLine componentsSeparatedByString:','.
    time ← values[0].
    latitude ← values[1].
    longitude ← values[2].
    magnitude ← values[4].
    magnitude doubleValue > 6 ifTrue:{
	stdout println:"Quake: magnitude {magnitude} on {time} at {latitude} {longitude}".
    }.
}. 
stream awaitResultForSeconds:20.
