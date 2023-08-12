
class EarthquakesReader {

  -main:args {
      var stdout.
      var awk.
      var lines.
      var stdin.
      stdin := class:MPWFDStreamSource Stdin.
      lines := class:MPWBytesToLines stream.
      stdout  := self Stdout retain.
	awk ← class:STAWK stream.
	awk setBlock: { :time :latitude :longitude :depth :magnitude |
            stdout print:'Magnitude: ', magnitude.
            stdout print:' latitude: ', latitude.
            stdout println:' longitude: ',longitude.
        }.
	awk setSeparator:','.
        stdin → lines.
	lines → awk.
        stdin run.
	0.      
  }
}
