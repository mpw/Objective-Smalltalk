#!env stsh
stream ← ref:https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv lines.
stream do: { :theLine |
    values ← theLine componentsSeparatedByString:','.
    time ← values at:0.
    latitude ← values at:1.
    longitude ← values at:2.
    magnitude ← values at:4.
	magnitude. time. latitude. longitude.
	stdout println:"Quake: magnitude {magnitude} on {time} at {latitude} {longitude}".
}. 
stream awaitResultForSeconds:5.
