#!env stsh
ref := ref:https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv
s ← ref stream.
f ← MPWBytesToLines stream.
class Quake {
	var time.
	var longitude.
	var latitude.
	var magnitude.
	-description { "Quake: magnitude {this:magnitude} on {this:time} at {this:latitude} {this:longitude}" }
}
filter quaker |{
    values ← object componentsSeparatedByString:','.
	quake ← Quake new.
    scheme:q := ref:var:quake/ asScheme.
    q:time ← values at:0.
    var:quake/latitude ← values at:1.
    var:quake/longitude ← values at:2.
    var:quake/magnitude ← values at:4.
	^quake
}. 
s → f → quaker → MPWPrintLiner → stdout.
s run.
shell runInteractiveLoop.
