
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
            magnitude := 'Magnitude: ', magnitude.
            magnitude :=  magnitude, ' latitude: ', latitude.
            stdout println:magnitude..
        }.
	awk setSeparator:','.
        stdin setTarget: lines.
	lines setTarget: awk.
        stdin run.
      
  }
}
