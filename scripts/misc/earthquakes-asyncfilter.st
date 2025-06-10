#!env stsh
stream ← ref:https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv linesAfter:1.
filter quakelogger  |{ 
    values ← object componentsSeparatedByString:','.
    time ← values[0].
    latitude ← values[1].
    longitude ← values[2].
    magnitude ← values[4].
    ^ "Quake: magnitude {magnitude} on {time} at {latitude} {longitude}".
}. 
(stream target target)  → #quakelogger{}  → stdline.
stream run:20
