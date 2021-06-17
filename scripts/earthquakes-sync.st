#!env stsh
data ← https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv.
lines ← data processedWith: MPWBytesToLines.
lines ← lines subarrayWithRange: (1 to: lines count - 1).
lines do: { :theLine |
    values ← theLine componentsSeparatedByString:','.
    time ← values at:0.
    latitude ← values at:1.
    longitude ← values at:2.
    magnitude ← values at:4.
	stdout println:"Quake: magnitude {magnitude} on {time} at {latitude} {longitude}".
}. 
