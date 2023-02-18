
class EarthquakesReader {

  -main:args {
      var stdout.
      var block.
      var awk.
      var lines.
      var stdin.
      var file.
      stdin := class:MPWFDStreamSource Stdin.
      lines := class:MPWBytesToLines stream.
      stdout  := self Stdout retain.
	awk ← class:STAWK stream.
	awk setBlock: { :time :latitude :longitude :depth :magnitude |
            stdout println:'Magnitude: ', magnitude stringValue.
        }.
	awk setSeparator:','.
        stdin setTarget: lines.
	lines setTarget: awk.
        stdin run.
      
  }
}
